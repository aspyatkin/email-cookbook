id = 'email'

%w(
  postgrey
).each do |package_name|
  package package_name do
    action :install
  end
end

service 'postgrey' do
  action [:enable, :start]
end

whitelist_recipients_conf = '/etc/postgrey/whitelist_recipients'

template whitelist_recipients_conf do
  source 'postgrey/whitelist_recipients.erb'
  mode 0644
  owner 'root'
  group node['root_group']
  variables(
    whitelist_recipients: node[id]['postgrey'].fetch('whitelist_recipients', [])
  )
  action :create
  notifies :restart, 'service[postgrey]', :delayed
end

whitelist_clients_conf = '/etc/postgrey/whitelist_clients'

template whitelist_clients_conf do
  source 'postgrey/whitelist_clients.erb'
  mode 0644
  owner 'root'
  group node['root_group']
  variables(
    whitelist_clients: node[id]['postgrey'].fetch('whitelist_clients', [])
  )
  action :create
  notifies :restart, 'service[postgrey]', :delayed
end

template '/etc/default/postgrey' do
  source 'postgrey/default.erb'
  mode 0644
  owner 'root'
  group node['root_group']
  variables(
    host: node[id]['postgrey']['host'],
    port: node[id]['postgrey']['port'],
    whitelist_clients: whitelist_clients_conf,
    whitelist_recipients: whitelist_recipients_conf
  )
  action :create
  notifies :restart, 'service[postgrey]', :delayed
end
