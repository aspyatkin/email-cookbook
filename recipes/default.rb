id = 'email'

include_recipe "localdns::default"

dns_local_records = {}

localdns_config 'localhost' do
  forward_servers node[id]['dns_forward_servers']
  local_records dns_local_records
  action :update
end

include_recipe "#{id}::prerequisite_postgres"
include_recipe "#{id}::prerequisite_php"
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
