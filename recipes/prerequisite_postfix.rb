id = 'email'

%w(sendmail).each do |package_name|
  package package_name do
    action :remove
  end
end

%w(postfix postfix-pgsql).each do |package_name|
  package package_name do
    action :install
  end
end

service 'postfix' do
  action [:enable, :start]
end

# directory node[id]['postfix']['map_files']['path'] do
#   mode 0755
#   owner node[id]['postfix']['map_files']['owner']
#   group node[id]['postfix']['map_files']['group']
#   recursive true
#   action :create
# end

# postgresql_database_user node[id]['postfix']['database']['user']  do
#   Chef::Resource::PostgresqlDatabaseUser.send :include, Email::Helper
#   connection postgres_connection_info
#   database_name node[id]['postfixadmin']['database']['name']
#   password data_bag_item('postgres', node.chef_environment)[
#     'credentials'][node[id]['postfix']['database']['user']]
#   privileges [:all]
#   action :create
# end

# node[id]['postfix']['map_files']['list'].each do |map_file|
#   template "#{node[id]['postfix']['map_files']['path']}/#{map_file}" do
#     source "postfix-pgsql/#{map_file}.erb"
#     mode 0644
#     owner node[id]['postfix']['map_files']['owner']
#     group node[id]['postfix']['map_files']['group']
#     variables(
#       user: node[id]['postfix']['database']['user'],
#       password: data_bag_item('postgres', node.chef_environment)[
#         'credentials'][node[id]['postfix']['database']['user']],
#       host: node[id]['postgres']['listen']['address'],
#       port: node[id]['postgres']['listen']['port'],
#       dbname: node[id]['postfixadmin']['database']['name']
#     )
#     action :create
#     notifies :reload, 'service[postfix]', :delayed
#   end
# end

tls_certificate node[id]['hostname'] do
  action :deploy
end

template "#{node[id]['postfix']['config']['root']}/main.cf" do
  ::Chef::Resource::Template.send(:include, ::ChefCookbook::TLS::Helper)
  source 'postfix/main.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    myhostname: node[id]['hostname'],
    mydomain: node[id]['domain'],
    smtpd_tls_cert_file: tls_certificate_path(node[id]['hostname']),
    smtpd_tls_key_file: tls_certificate_private_key_path(node[id]['hostname'])
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

template '/etc/aliases' do
  source 'postfix/aliases.erb'
  mode 0644
  owner 'root'
  group 'root'
  variables(
    aliases: {
      root: node[id]['postmaster_address']
    }
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

execute 'Configure aliases' do
  command 'newaliases'
  action :run
  notifies :reload, 'service[postfix]', :delayed
end

template "#{node[id]['postfix']['config']['root']}/vmailbox" do
  source 'postfix/virtual_mailboxes.erb'
  mode 0644
  owner node[id]['postfix']['config']['user']
  group node[id]['postfix']['config']['group']
  variables(
    virtual_mailboxes: node[id]['virtual_mailboxes']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

execute 'Configure virtual mailboxes' do
  command "postmap #{node[id]['postfix']['config']['root']}/vmailbox"
  action :run
  notifies :reload, 'service[postfix]', :delayed
end

template "#{node[id]['postfix']['config']['root']}/virtual" do
  source 'postfix/virtual_aliases.erb'
  mode 0644
  owner node[id]['postfix']['config']['user']
  group node[id]['postfix']['config']['group']
  variables(
    virtual_aliases: node[id]['virtual_aliases']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

execute 'Configure virtual aliases' do
  command "postmap #{node[id]['postfix']['config']['root']}/virtual"
  action :run
  notifies :reload, 'service[postfix]', :delayed
end

template "#{node[id]['postfix']['config']['root']}/master.cf" do
  source 'postfix/master.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  action :create
  notifies :reload, 'service[postfix]', :delayed
end
