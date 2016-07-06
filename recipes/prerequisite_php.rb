node.default['php']['install_method'] = 'package'

include_recipe 'php::default'

%w(curl gd pgsql imap).each do |package_name|
  package "php5-#{package_name}" do
    action :install
  end
end

execute 'Enable PHP imap' do
  command 'php5enmod imap'
  user 'root'
  group node['root_group']
  action :run
end
