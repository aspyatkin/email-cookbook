id = 'email'

%w(
  opendkim
  opendkim-tools
).each do |package_name|
  package package_name do
    action :install
  end
end

service 'opendkim' do
  action [:enable, :start]
end

config_basedir = node[id]['opendkim']['config']['root']

trusted_hosts_path = ::File.join config_basedir, 'TrustedHosts'
key_table_path = ::File.join config_basedir, 'KeyTable'
signing_table_path = ::File.join config_basedir, 'SigningTable'

directory config_basedir do
  mode 0755
  owner node[id]['opendkim']['service']['user']
  group node[id]['opendkim']['service']['group']
  recursive true
  action :create
end

template trusted_hosts_path do
  source 'opendkim/TrustedHosts.erb'
  mode 0644
  owner node[id]['opendkim']['service']['user']
  group node[id]['opendkim']['service']['group']
  variables(
    trusted_hosts: [
      'localhost',
      '127.0.0.1'
    ] + node[id]['sending_domains']
  )
  action :create
  notifies :reload, 'service[opendkim]', :delayed
end

key_basedir = ::File.join config_basedir, 'keys'

directory key_basedir do
  mode 0755
  owner node[id]['opendkim']['service']['user']
  group node[id]['opendkim']['service']['group']
  recursive true
  action :create
end

node[id]['sending_domains'].each do |sending_domain|
  key_domain_basedir = ::File.join key_basedir, sending_domain

  directory key_domain_basedir do
    mode 0755
    owner node[id]['opendkim']['service']['user']
    group node[id]['opendkim']['service']['group']
    recursive true
    action :create
  end

  private_key_file = ::File.join key_domain_basedir, "#{node[id]['opendkim']['selector']}.private"
  public_key_file = ::File.join key_domain_basedir, "#{node[id]['opendkim']['selector']}.txt"

  execute "Generate DKIM key for #{sending_domain}" do
    command "opendkim-genkey --bits 1024 --directory #{key_domain_basedir} --domain "\
            "#{sending_domain} --restrict --selector "\
            "#{node[id]['opendkim']['selector']}"
    user node[id]['opendkim']['service']['user']
    group node[id]['opendkim']['service']['group']
    not_if do
      ::File.exist?(private_key_file) && ::File.exist?(public_key_file)
    end
    creates private_key_file
    umask 002
    action :run
    notifies :reload, 'service[opendkim]', :delayed
  end
end

template key_table_path do
  source 'opendkim/KeyTable.erb'
  mode 0644
  owner node[id]['opendkim']['service']['user']
  group node[id]['opendkim']['service']['group']
  variables(
    domains: node[id]['sending_domains'],
    domainkey: node[id]['opendkim']['domainkey'],
    selector: node[id]['opendkim']['selector'],
    key_basedir: key_basedir
  )
  action :create
  notifies :reload, 'service[opendkim]', :delayed
end

template signing_table_path do
  source 'opendkim/SigningTable.erb'
  mode 0644
  owner node[id]['opendkim']['service']['user']
  group node[id]['opendkim']['service']['group']
  variables(
    domains: node[id]['sending_domains'],
    domainkey: node[id]['opendkim']['domainkey'],
    selector: node[id]['opendkim']['selector']
  )
  action :create
  notifies :reload, 'service[opendkim]', :delayed
end

template '/etc/opendkim.conf' do
  source 'opendkim/opendkim.conf.erb'
  mode 0644
  owner node[id]['opendkim']['config']['owner']
  group node[id]['opendkim']['config']['group']
  variables(
    trusted_hosts_file: trusted_hosts_path,
    key_table_file: key_table_path,
    signing_table_file: signing_table_path,
    port: node[id]['opendkim']['service']['port'],
    host: node[id]['opendkim']['service']['host'],
    user: node[id]['opendkim']['service']['user'],
    group: node[id]['opendkim']['service']['group']
  )
  action :create
  notifies :reload, 'service[opendkim]', :delayed
end
