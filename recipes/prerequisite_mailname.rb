id = 'email'

file '/etc/mailname' do
  mode 0644
  owner 'root'
  group node['root_group']
  content "#{node[id]['hostname']}\n"
  action :create
end
