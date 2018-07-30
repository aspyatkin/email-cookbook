id = 'email'

group node[id]['postfixadmin']['group'] do
  system true
  action :create
end

user node[id]['postfixadmin']['user'] do
  group node[id]['postfixadmin']['group']
  shell '/bin/false'
  system true
  action :create
end

ark 'postfixadmin' do
  url node[id]['postfixadmin']['url'] % {
    version: node[id]['postfixadmin']['version']
  }
  version node[id]['postfixadmin']['version']
  checksum node[id]['postfixadmin']['checksum']
  owner node[id]['postfixadmin']['user']
  group node[id]['postfixadmin']['group']
  action :install
end

helper = ::ChefCookbook::Email.new(node)

postgresql_database node[id]['postfixadmin']['database']['name'] do
  connection helper.postgres_connection_info
  action :create
end

postgresql_database_user node[id]['postfixadmin']['database']['user'] do
  connection helper.postgres_connection_info
  database_name node[id]['postfixadmin']['database']['name']
  password helper.postgres_user_password(
    node[id]['postfixadmin']['database']['user']
  )
  privileges [:all]
  action [:create, :grant]
end

php_fpm_pool 'postfixadmin' do
  listen node[id]['postfixadmin']['service']['listen_sock']
  user node[id]['postfixadmin']['user']
  group node[id]['postfixadmin']['group']
  process_manager 'dynamic'
  max_children node[id]['postfixadmin']['service']['pool']['max_children']
  start_servers node[id]['postfixadmin']['service']['pool']['start_servers']
  min_spare_servers \
    node[id]['postfixadmin']['service']['pool']['min_spare_servers']
  max_spare_servers \
    node[id]['postfixadmin']['service']['pool']['max_spare_servers']
  additional_config(
    'pm.max_requests' => \
      node[id]['postfixadmin']['service']['pool']['max_requests'],
    'listen.mode' => '0666',
    'php_admin_flag[log_errors]' => 'on',
    'php_value[date.timezone]' => 'UTC',
    'php_value[expose_php]' => 'off',
    'php_value[display_errors]' => 'off',
    'php_value[memory_limit]' => \
      node[id]['postfixadmin']['service']['php_memory_limit']
  )
end

mailbox_postdeletion_path = '/usr/local/bin/postfixadmin-mailbox-postdeletion'

template mailbox_postdeletion_path do
  source 'postfixadmin/mailbox-postdeletion.sh.erb'
  owner 'root'
  group node['root_group']
  mode 0755
  variables(
    basedir: node[id]['vmail']['home'],
    trashbase: node[id]['vmail']['trashbase'],
    db_host: node[id]['postgres']['host'],
    db_port: node[id]['postgres']['port'],
    db_user: node[id]['roundcube']['database']['user'],
    db_password: helper.postgres_user_password(
      node[id]['roundcube']['database']['user']
    ),
    db_name: node[id]['roundcube']['database']['name']
  )
  action :create
end

domain_postdeletion_path = '/usr/local/bin/postfixadmin-domain-postdeletion'

template domain_postdeletion_path do
  source 'postfixadmin/domain-postdeletion.sh.erb'
  owner 'root'
  group node['root_group']
  mode 0755
  variables(
    basedir: node[id]['vmail']['home'],
    trashbase: node[id]['vmail']['trashbase'],
    db_host: node[id]['postgres']['host'],
    db_port: node[id]['postgres']['port'],
    db_user: node[id]['roundcube']['database']['user'],
    db_password: helper.postgres_user_password(
      node[id]['roundcube']['database']['user']
    ),
    db_name: node[id]['roundcube']['database']['name']
  )
  action :create
end

file '/etc/sudoers.d/postfixadmin' do
  owner 'root'
  group node['root_group']
  content "#{node[id]['postfixadmin']['user']} ALL=("\
          "#{node[id]['vmail']['user']}) NOPASSWD: "\
          "#{mailbox_postdeletion_path}, #{domain_postdeletion_path}\n"
  mode 0440
  action :create
end

template 'config.local.php' do
  path "#{node['ark']['prefix_root']}/postfixadmin/config.local.php"
  source 'postfixadmin/config.local.php.erb'
  owner node[id]['postfixadmin']['user']
  group node[id]['postfixadmin']['group']
  mode 0640
  variables(
    db_type: 'pgsql',
    db_host: node[id]['postgres']['host'],
    db_port: node[id]['postgres']['port'],
    db_user: node[id]['postfixadmin']['database']['user'],
    db_password: helper.postgres_user_password(
      node[id]['postfixadmin']['database']['user']
    ),
    db_name: node[id]['postfixadmin']['database']['name'],
    setup_password: helper.postfixadmin_setup_password,
    fqdn: node[id]['admin_fqdn'],
    admin_address: node[id]['admin_address'],
    quota_multiplier: node[id]['postfixadmin']['quota_multiplier'],
    vmail_user: node[id]['vmail']['user'],
    mailbox_postdeletion_path: mailbox_postdeletion_path,
    domain_postdeletion_path: domain_postdeletion_path,
    emailcheck_resolve_domain: node.chef_environment.start_with?('production')
  )
end

fastcgi_pass = "unix:#{node[id]['postfixadmin']['service']['listen_sock']}"

tls_rsa_certificate node[id]['admin_fqdn'] do
  action :deploy
end

tls_rsa_item = ::ChefCookbook::TLS.new(node).rsa_certificate_entry(node[id]['admin_fqdn'])
tls_ec_item = nil

if node[id]['postfixadmin']['service']['use_ec_certificate']
  tls_ec_certificate node[id]['admin_fqdn'] do
    action :deploy
  end

  tls_ec_item = ::ChefCookbook::TLS.new(node).ec_certificate_entry(node[id]['admin_fqdn'])
end

has_scts = tls_rsa_item.has_scts? && (tls_ec_item.nil? ? true : tls_ec_item.has_scts?)

nginx_conf_variables = {
  name: 'postfixadmin',
  server_name: node[id]['admin_fqdn'],
  docroot: "#{node['ark']['prefix_root']}/postfixadmin",
  insecure_port: 80,
  secure_port: 443,
  ssl_rsa_certificate: tls_rsa_item.certificate_path,
  ssl_rsa_certificate_key: tls_rsa_item.certificate_private_key_path,
  ssl_ec_certificate: tls_ec_item.nil? ? nil : tls_ec_item.certificate_path,
  ssl_ec_certificate_key: \
    tls_ec_item.nil? ? nil : tls_ec_item.certificate_private_key_path,
  hsts: true,
  hsts_max_age: node[id]['postfixadmin']['service']['hsts_max_age'],
  oscp_stapling: false,
  scts: has_scts,
  hpkp: false,
  fastcgi_pass: fastcgi_pass,
  disable_setup_page: node[id]['postfixadmin']['service']['disable_setup_page']
}

if node.chef_environment.start_with?('staging', 'production')
  nginx_conf_variables.merge!(
    oscp_stapling: true,
    scts_rsa_directory: tls_rsa_item.scts_dir,
    scts_ec_directory: tls_ec_item.nil? ? nil : tls_ec_item.scts_dir,
    hpkp: true,
    hpkp_pins: (
      tls_rsa_item.hpkp_pins + (tls_ec_item.nil? ? [] : tls_ec_item.hpkp_pins)
    ).uniq,
    hpkp_max_age: node[id]['postfixadmin']['service']['hpkp_max_age']
  )
end

nginx_site 'postfixadmin' do
  template 'postfixadmin/nginx.conf.erb'
  variables nginx_conf_variables
  action :enable
end
