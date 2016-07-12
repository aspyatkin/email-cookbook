id = 'email'

include_recipe "#{id}::prerequisite_postgres"
include_recipe "#{id}::prerequisite_php"
include_recipe "#{id}::prerequisite_nginx"
include_recipe "#{id}::prerequisite_postfixadmin"

include_recipe 'tls::default'

include_recipe "#{id}::prerequisite_mailname"
include_recipe "#{id}::prerequisite_vmail"
include_recipe "#{id}::prerequisite_opendkim"
include_recipe "#{id}::prerequisite_postgrey"
include_recipe "#{id}::prerequisite_spamassassin"
include_recipe "#{id}::prerequisite_amavis"
include_recipe "#{id}::prerequisite_postfix"
include_recipe "#{id}::prerequisite_dovecot"
