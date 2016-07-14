id = 'email'

php_pear_channel 'pear.php.net' do
  action :update
end

[
  ['Mail_mime', '1.10.0', 'stable'],
  ['Net_IDNA2', '0.1.1', 'beta'],
  ['Net_SMTP', '1.7.2', 'stable']
].each do |entry|
  php_pear entry[0] do
    version entry[1]
    preferred_state entry[2]
    action :install
  end
end

group node[id]['roundcube']['group'] do
  system true
  action :create
end

user node[id]['roundcube']['user'] do
  group node[id]['roundcube']['group']
  shell '/bin/false'
  system true
  action :create
end

ark 'roundcube' do
  url node[id]['roundcube']['url'] % {
    version: node[id]['roundcube']['version']
  }
  version node[id]['roundcube']['version']
  checksum node[id]['roundcube']['checksum']
  owner node[id]['roundcube']['user']
  group node[id]['roundcube']['group']
  action :install
end

helper = ChefCookbook::Email.new node

postgresql_database node[id]['roundcube']['database']['name'] do
  connection helper.postgres_connection_info
  action :create
end

postgresql_database_user node[id]['roundcube']['database']['user'] do
  connection helper.postgres_connection_info
  database_name node[id]['roundcube']['database']['name']
  password helper.postgres_user_password(
    node[id]['roundcube']['database']['user']
  )
  privileges [:all]
  action [:create, :grant]
end

composer_project "#{node['ark']['prefix_root']}/roundcube" do
  dev false
  quiet false
  prefer_dist false
  user node[id]['roundcube']['user']
  group node[id]['roundcube']['group']
  action :install
end

config_file_path = ::File.join(
  node['ark']['prefix_root'],
  'roundcube',
  'config',
  'config.inc.php'
)

template config_file_path do
  source 'roundcube/config.inc.php.erb'
  mode 0644
  owner node[id]['roundcube']['user']
  group node[id]['roundcube']['group']
  variables(
    enable_installer: node[id]['roundcube']['service']['enable_installer'],
    hostname: node[id]['hostname'],
    db_user: node[id]['roundcube']['database']['user'],
    db_password: helper.postgres_user_password(
      node[id]['roundcube']['database']['user']
    ),
    db_host: node[id]['postgres']['host'],
    db_port: node[id]['postgres']['port'],
    db_name: node[id]['roundcube']['database']['name'],
    des_key: data_bag_item('roundcube', node.chef_environment)['des_key']
  )
  action :create
end

php_fpm_pool 'roundcube' do
  listen node[id]['roundcube']['service']['listen_sock']
  user node[id]['roundcube']['user']
  group node[id]['roundcube']['group']
  process_manager 'dynamic'
  max_children node[id]['roundcube']['service']['pool']['max_children']
  start_servers node[id]['roundcube']['service']['pool']['start_servers']
  min_spare_servers \
    node[id]['roundcube']['service']['pool']['min_spare_servers']
  max_spare_servers \
    node[id]['roundcube']['service']['pool']['max_spare_servers']
  additional_config(
    'pm.max_requests' => \
      node[id]['roundcube']['service']['pool']['max_requests'],
    'listen.mode' => '0666',
    'php_flag[display_errors]' => 'off',
    'php_flag[log_errors]' => 'on',
    'php_value[error_log]' => 'logs/errors',
    'php_value[date.timezone]' => 'UTC',
    'php_value[expose_php]' => 'off',
    'php_value[upload_max_filesize]' => '5M',
    'php_value[post_max_size]' => '6M',
    'php_value[memory_limit]' => \
      node[id]['roundcube']['service']['php_memory_limit'],
    'php_flag[register_globals]' => 'off',
    'php_flag[zlib.output_compression]' => 'off',
    'php_flag[magic_quotes_gpc]' => 'off',
    'php_flag[magic_quotes_runtime]' => 'off',
    'php_flag[suhosin.session.encrypt]' => 'off',
    'php_value[session.cookie_path]' => '/',
    'php_value[session.hash_function]' => 'sha256',
    'php_flag[session.auto_start]' => 'off',
    'php_value[session.gc_maxlifetime]' => '21600',
    'php_value[session.gc_divisor]' => '500',
    'php_value[session.gc_probability]' => '1'
  )
end

fastcgi_pass = "unix:#{node[id]['roundcube']['service']['listen_sock']}"

tls_certificate node[id]['webmail_fqdn'] do
  action :deploy
end

tls_item = ChefCookbook::TLS.new(node).certificate_entry node[id]['webmail_fqdn']

nginx_conf_variables = {
  name: 'roundcube',
  server_name: node[id]['webmail_fqdn'],
  docroot: "#{node['ark']['prefix_root']}/roundcube",
  insecure_port: 80,
  secure_port: 443,
  ssl_certificate: tls_item.certificate_path,
  ssl_certificate_key: tls_item.certificate_private_key_path,
  hsts: true,
  hsts_max_age: node[id]['roundcube']['service']['hsts_max_age'],
  oscp_stapling: false,
  scts: false,
  hpkp: false,
  fastcgi_pass: fastcgi_pass,
  enable_installer: node[id]['roundcube']['service']['enable_installer']
}

if node.chef_environment.start_with?('staging', 'production')
  nginx_conf_variables.merge!(
    oscp_stapling: true,
    scts: true,
    scts_directory: tls_item.scts_dir,
    hpkp: true,
    hpkp_pins: tls_item.hpkp_pins,
    hpkp_max_age: node[id]['roundcube']['service']['hpkp_max_age']
  )
end

template 'RoundCube service nginx configuration' do
  path ::File.join node['nginx']['dir'], 'sites-available', 'roundcube.conf'
  source 'roundcube/nginx.conf.erb'
  mode 0644
  variables nginx_conf_variables
  notifies :reload, 'service[nginx]', :delayed
end

nginx_site 'roundcube.conf' do
  enabled true
end
