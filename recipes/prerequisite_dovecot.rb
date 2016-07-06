id = 'email'

%w(
  dovecot-core
  dovecot-imapd
  dovecot-sieve
  dovecot-lmtpd
  dovecot-pgsql
).each do |package_name|
  package package_name do
    action :install
  end
end

service 'dovecot' do
  action [:enable, :start]
end

tls_certificate node[id]['hostname'] do
  action :deploy
end

helper = ChefCookbook::Email.new node

# postgresql_database_user node[id]['dovecot']['database']['user'] do
#   connection helper.postgres_connection_info
#   database_name node[id]['postfixadmin']['database']['name']
#   password helper.postgres_user_password(
#     node[id]['dovecot']['database']['user']
#   )
#   privileges [:all]
#   action [:create, :grant]
# end

template "#{node[id]['dovecot']['config']['root']}/dovecot.conf" do
  source 'dovecot/dovecot.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/10-auth.conf" do
  source 'dovecot/10-auth.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/10-mail.conf" do
  source 'dovecot/10-mail.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    mail_uid: node[id]['vmail']['user'],
    mail_gid: node[id]['vmail']['group'],
    mail_home: node[id]['vmail']['home']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

# template "#{node[id]['dovecot']['config']['root']}/conf.d/auth-passwdfile.conf.ext" do
#   source 'dovecot/auth-passwdfile.conf.ext.erb'
#   mode 0644
#   owner node[id]['dovecot']['config']['owner']
#   group node[id]['dovecot']['config']['group']
#   variables(
#     db_file: "#{node[id]['dovecot']['config']['root']}/#{node[id]['dovecot']['config']['db_file']}"
#   )
#   action :create
#   notifies :reload, 'service[dovecot]', :delayed
# end

sql_conf_file = ::File.join(
  node[id]['dovecot']['config']['root'],
  'dovecot-sql.conf.ext'
)

helper = ChefCookbook::Email.new node

template sql_conf_file do
  source 'dovecot/dovecot-sql.conf.ext.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    db_user: node[id]['dovecot']['database']['user'],
    db_password: helper.postgres_user_password(
      node[id]['dovecot']['database']['user']
    ),
    db_host: node[id]['postgres']['host'],
    db_port: node[id]['postgres']['port'],
    db_name: node[id]['postfixadmin']['database']['name'],
    vmail_home: node[id]['vmail']['home'],
    vmail_uid: node[id]['vmail']['uid'],
    vmail_gid: node[id]['vmail']['gid']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/auth-sql.conf.ext" do
  source 'dovecot/auth-sql.conf.ext.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    sql_conf_file: sql_conf_file
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

# template "#{node[id]['dovecot']['config']['root']}/create_mail_user" do
#   source 'dovecot/create_mail_user.sh.erb'
#   mode 0755
#   owner node[id]['dovecot']['config']['owner']
#   group node[id]['dovecot']['config']['group']
#   variables(
#     db_file: "#{node[id]['dovecot']['config']['root']}/#{node[id]['dovecot']['config']['db_file']}"
#   )
#   action :create
#   notifies :reload, 'service[dovecot]', :delayed
# end

template "#{node[id]['dovecot']['config']['root']}/conf.d/10-master.conf" do
  source 'dovecot/10-master.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    vmail_user: node[id]['vmail']['user'],
    postfix_user: node[id]['postfix']['service']['user'],
    postfix_group: node[id]['postfix']['service']['group']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

tls_item = ::ChefCookbook::TLS.new(node).certificate_entry node[id]['hostname']

template "#{node[id]['dovecot']['config']['root']}/conf.d/10-ssl.conf" do
  source 'dovecot/10-ssl.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    ssl_cert: tls_item.certificate_path,
    ssl_key: tls_item.certificate_private_key_path
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/20-lmtp.conf" do
  source 'dovecot/20-lmtp.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    postmaster_address: node[id]['postmaster_address'],
    hostname: node[id]['hostname']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end
