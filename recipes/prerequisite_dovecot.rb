id = 'email'

%w(
  dovecot-core
  dovecot-imapd
  dovecot-pop3d
  dovecot-sieve
  dovecot-lmtpd
  dovecot-pgsql
  dovecot-sieve
  dovecot-managesieved
).each do |package_name|
  package package_name do
    action :install
  end
end

service 'dovecot' do
  action [:enable, :start]
end

helper = ChefCookbook::Email.new node

postgresql_database_user 'Create Dovecot database user' do
  username node[id]['dovecot']['database']['user']
  connection helper.postgres_connection_info
  password helper.postgres_user_password(
    node[id]['dovecot']['database']['user']
  )
  action :create
end

%w(
  mailbox
  domain
).each do |table_name|
  postgresql_database 'Grant select privileges to Dovecot database user on '\
                      "#{table_name} table" do
    connection helper.postgres_connection_info
    database_name node[id]['postfixadmin']['database']['name']
    sql %(
      GRANT SELECT ON "#{table_name}"
      TO "#{node[id]['dovecot']['database']['user']}"
    )
    action :query
  end
end

%w(
  domain
).each do |table_name|
  postgresql_database 'Grant privileges to Dovecot database user on '\
                      "#{table_name} table" do
    connection helper.postgres_connection_info
    database_name node[id]['postfixadmin']['database']['name']
    sql %(
      GRANT SELECT, UPDATE ON "#{table_name}"
      TO "#{node[id]['dovecot']['database']['user']}"
    )
    action :query
  end
end

%w(
  quota2
).each do |table_name|
  postgresql_database 'Grant privileges to Dovecot database user on '\
                      "#{table_name} table" do
    connection helper.postgres_connection_info
    database_name node[id]['postfixadmin']['database']['name']
    sql %(
      GRANT SELECT, INSERT, UPDATE, DELETE ON "#{table_name}"
      TO "#{node[id]['dovecot']['database']['user']}"
    )
    action :query
  end
end

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

template "#{node[id]['dovecot']['config']['root']}/conf.d/10-logging.conf" do
  source 'dovecot/10-logging.conf.erb'
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
    vmail_gid: node[id]['vmail']['gid'],
    quota_multiplier: node[id]['postfixadmin']['quota_multiplier']
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

dict_user_quota_options = ::File.join(
  node[id]['dovecot']['config']['root'],
  'dovecot-dict-sql-user.conf'
)

template dict_user_quota_options do
  source 'dovecot/dovecot-dict-sql-user.conf.erb'
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
    db_name: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/10-master.conf" do
  source 'dovecot/10-master.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    vmail_user: node[id]['vmail']['user'],
    vmail_group: node[id]['vmail']['group'],
    postfix_user: node[id]['postfix']['service']['user'],
    postfix_group: node[id]['postfix']['service']['group']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

tls_vlt_provider = lambda { nil }

unless node[id]['vlt_tls_prefix'].nil?
  tls_vlt = ::Vlt::Client.new(::Vlt.file_auth_provider, node[id]['vlt_tls_prefix'])
  tls_vlt_provider = lambda { tls_vlt }
end

tls = ::ChefCookbook::TLS.new(node, vlt_provider: tls_vlt_provider, vlt_format: node[id]['vlt_format'])

tls_rsa_certificate node[id]['hostname'] do
  vlt_provider tls_vlt_provider
  vlt_format node[id]['vlt_format']
  action :deploy
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/10-ssl.conf" do
  source 'dovecot/10-ssl.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    ssl_entry: tls.rsa_certificate_entry(node[id]['hostname'])
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/15-lda.conf" do
  source 'dovecot/15-lda.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/15-mailboxes.conf" do
  source 'dovecot/15-mailboxes.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
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

template "#{node[id]['dovecot']['config']['root']}/conf.d/20-imap.conf" do
  source 'dovecot/20-imap.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/20-pop3.conf" do
  source 'dovecot/20-pop3.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

quota_warning_path = '/usr/local/bin/dovecot-quota-warning'

template quota_warning_path do
  source 'dovecot/quota-warning.sh.erb'
  mode 0755
  owner 'root'
  group node['root_group']
  variables(
    admin_address: node[id]['admin_address']
  )
  action :create
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/90-quota.conf" do
  source 'dovecot/90-quota.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    dict_user_quota_options: dict_user_quota_options,
    quota_status_host: node[id]['dovecot']['quota_status']['host'],
    quota_status_port: node[id]['dovecot']['quota_status']['port'],
    quota_warning_path: quota_warning_path,
    vmail_user: node[id]['vmail']['user']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

sieve_basedir = '/var/lib/dovecot/sieve'

directory sieve_basedir do
  mode 0755
  owner 'root'
  group node['root_group']
  recursive true
  action :create
end

sieve_global_dir = ::File.join(sieve_basedir, 'global')

directory sieve_global_dir do
  mode 0755
  owner 'root'
  group node['root_group']
  action :create
end

sieve_private_dir = ::File.join(sieve_basedir, 'private')

directory sieve_private_dir do
  mode 0700
  owner node[id]['vmail']['user']
  group node['root_group']
  action :create
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/90-sieve.conf" do
  source 'dovecot/90-sieve.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
    sieve_global_dir: sieve_global_dir,
    sieve_private_dir: sieve_private_dir,
    sieve_max_actions: node[id]['dovecot']['config']['sieve']['max_actions'],
    sieve_max_redirects: node[id]['dovecot']['config']['sieve']['max_redirects']
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end

template "#{node[id]['dovecot']['config']['root']}/conf.d/20-managesieve.conf" do
  source 'dovecot/20-managesieve.conf.erb'
  mode 0644
  owner node[id]['dovecot']['config']['owner']
  group node[id]['dovecot']['config']['group']
  variables(
  )
  action :create
  notifies :reload, 'service[dovecot]', :delayed
end
