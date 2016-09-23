id = 'email'

include_recipe "#{id}::prerequisite_postgres"
include_recipe "#{id}::prerequisite_php"
include_recipe "#{id}::prerequisite_nginx"
include_recipe "#{id}::prerequisite_postfixadmin"
include_recipe "#{id}::prerequisite_mailname"
include_recipe "#{id}::prerequisite_vmail"
include_recipe "#{id}::prerequisite_opendkim"
include_recipe "#{id}::prerequisite_postgrey"
include_recipe "#{id}::prerequisite_spamassassin"
include_recipe "#{id}::prerequisite_clamav"
include_recipe "#{id}::prerequisite_amavis"
include_recipe "#{id}::prerequisite_policyd_spf"
include_recipe "#{id}::prerequisite_postfix"
include_recipe "#{id}::prerequisite_dovecot"
include_recipe "#{id}::prerequisite_roundcube"

if node.chef_environment.start_with?('development')
  tls_ca_certificate 'IndigoByte_Development_CA' do
    action :install
  end
end

if node.chef_environment.start_with?('staging')
  tls_ca_certificate 'IndigoByte_Staging_CA' do
    action :install
  end
end
