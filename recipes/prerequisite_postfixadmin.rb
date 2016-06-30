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

postgresql_database node[id]['postfixadmin']['database']['name'] do
  Chef::Resource::PostgresqlDatabase.send :include, Email::Helper
  connection postgres_connection_info
  action :create
end

postgresql_database_user node[id]['postfixadmin']['database']['user'] do
  Chef::Resource::PostgresqlDatabaseUser.send :include, Email::Helper
  connection postgres_connection_info
  database_name node[id]['postfixadmin']['database']['name']
  password data_bag_item('postgres', node.chef_environment)[
    'credentials'][node[id]['postfixadmin']['database']['user']]
  privileges [:all]
  action [:create, :grant]
end

php_fpm_pool 'postfixadmin' do
  listen node[id]['postfixadmin']['listen_sock']
  user node[id]['postfixadmin']['user']
  group node[id]['postfixadmin']['group']
  process_manager 'dynamic'
  max_children node[id]['postfixadmin']['pool']['max_children']
  start_servers node[id]['postfixadmin']['pool']['start_servers']
  min_spare_servers node[id]['postfixadmin']['pool']['min_spare_servers']
  max_spare_servers node[id]['postfixadmin']['pool']['max_spare_servers']
  additional_config(
    'pm.max_requests' => node[id]['postfixadmin']['pool']['max_requests'],
    'listen.mode' => '0666',
    'php_admin_flag[log_errors]' => 'on',
    'php_value[date.timezone]' => 'UTC',
    'php_value[expose_php]' => 'off',
    'php_value[display_errors]' => 'off',
    'php_value[memory_limit]' => node[id]['postfixadmin']['php_memory_limit']
  )
end

template 'config.local.php' do
  Chef::Resource::Template.send :include, Email::PHP
  path "#{node['ark']['prefix_root']}/postfixadmin/config.local.php"
  source 'postfixadmin.config.local.php.erb'
  owner node[id]['postfixadmin']['user']
  group node[id]['postfixadmin']['group']
  mode 0640
  variables(
    db_type: 'pgsql',
    db_host: node[id]['postgres']['listen']['address'],
    db_port: node[id]['postgres']['listen']['port'],
    db_user: node[id]['postfixadmin']['database']['user'],
    db_password: data_bag_item('postgres', node.chef_environment)[
      'credentials'][node[id]['postfixadmin']['database']['user']],
    db_name: node[id]['postfixadmin']['database']['name'],
    domain: node[id]['domain'],
    server_name: node[id]['postfixadmin']['server_name'],
    setup_password: encrypt_setup_password(
      data_bag_item('postfixadmin', node.chef_environment)['admin_credentials']['password'],
      data_bag_item('postfixadmin', node.chef_environment)['admin_credentials']['salt']
    ),
    conf: node[id]['postfixadmin']['conf']
  )
end

fastcgi_pass =
  "unix:#{node[id]['postfixadmin']['listen_sock']}"

template 'Mantis service nginx configuration' do
  path ::File.join node['nginx']['dir'], 'sites-available', 'postfixadmin.conf'
  source 'postfixadmin.nginx.conf.erb'
  mode 0644
  variables(
    name: 'postfixadmin',
    server_name: node[id]['postfixadmin']['server_name'],
    docroot: "#{node['ark']['prefix_root']}/postfixadmin",
    port: 80,
    fastcgi_pass: fastcgi_pass
  )
  notifies :reload, 'service[nginx]', :delayed
end

nginx_site 'postfixadmin.conf' do
  enabled true
end
