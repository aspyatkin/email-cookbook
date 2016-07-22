id = 'email'

%w(
  postfix-policyd-spf-python
).each do |package_name|
  package package_name do
    action :install
  end
end

template '/etc/postfix-policyd-spf-python/policyd-spf.conf' do
  source 'policyd-spf/default.conf.erb'
  mode 0644
  owner 'root'
  group node['root_group']
  action :create
  notifies :reload, 'service[postfix]', :delayed
end
