id = 'email'

# include_recipe "#{id}::prerequisite_postgres"
# include_recipe "#{id}::prerequisite_php"
# include_recipe "#{id}::prerequisite_nginx"
# include_recipe "#{id}::prerequisite_postfixadmin"
include_recipe "#{id}::prerequisite_vmail"
include_recipe "#{id}::prerequisite_postfix"
include_recipe "#{id}::prerequisite_dovecot"
