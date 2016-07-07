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

template '/etc/default/postgrey' do
  source 'postgrey/default.erb'
  mode 0644
  owner 'root'
  group node['root_group']
  variables(
    host: node[id]['postgrey']['host'],
    port: node[id]['postgrey']['port']
  )
  action :create
  notifies :restart, 'service[postgrey]', :delayed
end
