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

postfix_maps_basedir = ::File.join(
  node[id]['postfix']['config']['root'],
  'postgres'
)

directory postfix_maps_basedir do
  mode 0755
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  recursive true
  action :create
end

helper = ChefCookbook::Email.new node

postgresql_database_user 'Create Postfix database user' do
  username node[id]['postfix']['database']['user']
  connection helper.postgres_connection_info
  password helper.postgres_user_password(
    node[id]['postfix']['database']['user']
  )
  action :create
end

%w(
  domain
  alias_domain
  alias
  mailbox
).each do |table_name|
  postgresql_database 'Grant privileges to Postfix database user on '\
                      "#{table_name} table" do
    connection helper.postgres_connection_info
    database_name node[id]['postfixadmin']['database']['name']
    sql %(
      GRANT SELECT ON "#{table_name}"
      TO "#{node[id]['postfix']['database']['user']}"
    )
    action :query
  end
end

db_virtual_domains_maps_file = ::File.join(
  postfix_maps_basedir,
  'virtual_domains_maps.cf'
)

template db_virtual_domains_maps_file do
  source 'postfix/db_virtual_domains_maps.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    user: node[id]['postfix']['database']['user'],
    password: helper.postgres_user_password(
      node[id]['postfix']['database']['user']
    ),
    host: node[id]['postgres']['host'],
    port: node[id]['postgres']['port'],
    dbname: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

db_virtual_alias_maps_file = ::File.join(
  postfix_maps_basedir,
  'virtual_alias_maps.cf'
)

template db_virtual_alias_maps_file do
  source 'postfix/db_virtual_alias_maps.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    user: node[id]['postfix']['database']['user'],
    password: helper.postgres_user_password(
      node[id]['postfix']['database']['user']
    ),
    host: node[id]['postgres']['host'],
    port: node[id]['postgres']['port'],
    dbname: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

db_virtual_alias_domain_maps_file = ::File.join(
  postfix_maps_basedir,
  'virtual_alias_domain_maps.cf'
)

template db_virtual_alias_domain_maps_file do
  source 'postfix/db_virtual_alias_domain_maps.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    user: node[id]['postfix']['database']['user'],
    password: helper.postgres_user_password(
      node[id]['postfix']['database']['user']
    ),
    host: node[id]['postgres']['host'],
    port: node[id]['postgres']['port'],
    dbname: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

db_virtual_alias_domain_catchall_maps_file = ::File.join(
  postfix_maps_basedir,
  'virtual_alias_domain_catchall_maps.cf'
)

template db_virtual_alias_domain_catchall_maps_file do
  source 'postfix/db_virtual_alias_domain_catchall_maps.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    user: node[id]['postfix']['database']['user'],
    password: helper.postgres_user_password(
      node[id]['postfix']['database']['user']
    ),
    host: node[id]['postgres']['host'],
    port: node[id]['postgres']['port'],
    dbname: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

db_virtual_mailbox_maps_file = ::File.join(
  postfix_maps_basedir,
  'virtual_mailbox_maps.cf'
)

template db_virtual_mailbox_maps_file do
  source 'postfix/db_virtual_mailbox_maps.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    user: node[id]['postfix']['database']['user'],
    password: helper.postgres_user_password(
      node[id]['postfix']['database']['user']
    ),
    host: node[id]['postgres']['host'],
    port: node[id]['postgres']['port'],
    dbname: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

db_virtual_alias_domain_mailbox_maps_file = ::File.join(
  postfix_maps_basedir,
  'virtual_alias_domain_mailbox_maps.cf'
)

template db_virtual_alias_domain_mailbox_maps_file do
  source 'postfix/db_virtual_alias_domain_mailbox_maps.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    user: node[id]['postfix']['database']['user'],
    password: helper.postgres_user_password(
      node[id]['postfix']['database']['user']
    ),
    host: node[id]['postgres']['host'],
    port: node[id]['postgres']['port'],
    dbname: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :reload, 'service[postfix]', :delayed
end

dh_512_path = ::File.join node[id]['postfix']['config']['root'], 'dh_512'

execute "openssl gendh -out #{dh_512_path} -2 512" do
  user 'root'
  group node['root_group']
  creates dh_512_path
  action :run
end

dh_1024_path = ::File.join node[id]['postfix']['config']['root'], 'dh_1024'

execute "openssl gendh -out #{dh_1024_path} -2 1024" do
  user 'root'
  group node['root_group']
  creates dh_1024_path
  action :run
end

tls_certificate node[id]['hostname'] do
  action :deploy
end

tls_item = ::ChefCookbook::TLS.new(node).certificate_entry node[id]['hostname']

template "#{node[id]['postfix']['config']['root']}/main.cf" do
  source 'postfix/main.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  variables(
    hostname: node[id]['hostname'],
    domain: node[id]['domain'],
    smtpd_tls_cert_file: tls_item.certificate_path,
    smtpd_tls_key_file: tls_item.certificate_private_key_path,
    opendkim_host: node[id]['opendkim']['service']['host'],
    opendkim_port: node[id]['opendkim']['service']['port'],
    virtual_domains_maps_file: db_virtual_domains_maps_file,
    virtual_alias_maps_file: db_virtual_alias_maps_file,
    virtual_alias_domain_maps_file: db_virtual_alias_domain_maps_file,
    virtual_alias_domain_catchall_maps_file: \
      db_virtual_alias_domain_catchall_maps_file,
    virtual_mailbox_maps_file: db_virtual_mailbox_maps_file,
    virtual_alias_domain_mailbox_maps_file: \
      db_virtual_alias_domain_mailbox_maps_file,
    smtpd_tls_dh1024_param_file: dh_1024_path,
    smtpd_tls_dh512_param_file: dh_512_path,
    postgrey_host: node[id]['postgrey']['host'],
    postgrey_port: node[id]['postgrey']['port'],
    amavis_host: node[id]['amavis']['service']['host'],
    amavis_port: node[id]['amavis']['service']['port']
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

template "#{node[id]['postfix']['config']['root']}/master.cf" do
  source 'postfix/master.cf.erb'
  mode 0644
  owner node[id]['postfix']['config']['owner']
  group node[id]['postfix']['config']['group']
  action :create
  notifies :reload, 'service[postfix]', :delayed
end
