id = 'email'

%w(
  amavisd-new
  libdbi-perl
  libdbd-pg-perl
).each do |package_name|
  package package_name do
    action :install
  end
end

helper = ChefCookbook::Email.new node

postgresql_database_user 'Create Amavis database user' do
  username node[id]['amavis']['database']['user']
  connection helper.postgres_connection_info
  password helper.postgres_user_password(
    node[id]['amavis']['database']['user']
  )
  action :create
end

%w(
  domain
).each do |table_name|
  postgresql_database 'Grant privileges to Amavis database user on '\
                      "#{table_name} table" do
    connection helper.postgres_connection_info
    database_name node[id]['postfixadmin']['database']['name']
    sql %(
      GRANT SELECT ON "#{table_name}"
      TO "#{node[id]['amavis']['database']['user']}"
    )
    action :query
  end
end

template "#{node[id]['amavis']['config']['root']}"\
         '/conf.d/15-content_filter_mode' do
  source 'amavis/15-content_filter_mode.erb'
  mode 0644
  owner node[id]['amavis']['config']['owner']
  group node[id]['amavis']['config']['group']
  action :create
  notifies :restart, 'service[amavis]', :delayed
end

template "#{node[id]['amavis']['config']['root']}"\
         '/conf.d/50-user' do
  source 'amavis/50-user.erb'
  mode 0644
  owner node[id]['amavis']['config']['owner']
  group node[id]['amavis']['config']['group']
  variables(
    domain: node[id]['domain'],
    hostname: node[id]['hostname'],
    sending_domains: node[id]['sending_domains'],
    listen_port: node[id]['amavis']['service']['port'],
    max_servers: node[id]['amavis']['service']['max_servers'],
    db_user: node[id]['amavis']['database']['user'],
    db_password: helper.postgres_user_password(
      node[id]['amavis']['database']['user']
    ),
    db_host: node[id]['postgres']['host'],
    db_port: node[id]['postgres']['port'],
    db_name: node[id]['postfixadmin']['database']['name']
  )
  action :create
  notifies :restart, 'service[amavis]', :delayed
end

group node[id]['amavis']['service']['group'] do
  append true
  members node[id]['clamav']['service']['user']
  action :modify
end

group node[id]['clamav']['service']['group'] do
  append true
  members node[id]['amavis']['service']['user']
  action :modify
end

service 'amavis' do
  action [:enable, :start]
end
