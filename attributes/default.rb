id = 'email'

# default[id]['postgres']['version'] = '9.5'
# default[id]['postgres']['listen']['address'] = '127.0.0.1'
# default[id]['postgres']['listen']['port'] = 5432

# default[id]['postfixadmin']['user'] = 'postfixadmin'
# default[id]['postfixadmin']['group'] = 'postfixadmin'

# default[id]['postfixadmin']['version'] = '2.3.8'
# default[id]['postfixadmin']['url'] =
#   'http://downloads.sourceforge.net/project/postfixadmin/postfixadmin/'\
#   'postfixadmin-%{version}/postfixadmin-%{version}.tar.gz'
# default[id]['postfixadmin']['checksum'] =
#   '8969b3312935c6e94ff17508f5b7e78b65828cd52d371adde3bfd9206597d94a'

# default[id]['postfixadmin']['database']['name'] = 'postfixadmin'
# default[id]['postfixadmin']['database']['user'] = 'postfixadmin'

# default[id]['postfixadmin']['pool']['max_childen'] = 5
# default[id]['postfixadmin']['pool']['start_servers'] = 2
# default[id]['postfixadmin']['pool']['min_spare_servers'] = 1
# default[id]['postfixadmin']['pool']['max_spare_servers'] = 3
# default[id]['postfixadmin']['pool']['max_requests'] = 100
# default[id]['postfixadmin']['php_memory_limit'] = '64M'
# default[id]['postfixadmin']['listen_sock'] = '/var/run/php-fpm-postfixadmin.sock'

# default[id]['postfixadmin']['conf']['encrypt'] = 'md5crypt'
# default[id]['postfixadmin']['conf']['domain_path'] = 'YES'
# default[id]['postfixadmin']['conf']['domain_in_mailbox'] = 'NO'
# default[id]['postfixadmin']['conf']['fetchmail'] = 'NO'

# default[id]['postfixadmin']['conf']['create_mailbox_subdirs_prefix'] = ''
# default[id]['postfixadmin']['conf']['new_quota_table'] = 'YES'

default[id]['vmail']['user'] = 'vmail'
# default[id]['vmail']['uid'] = 2000
default[id]['vmail']['group'] = 'vmail'
# default[id]['vmail']['gid'] = 2000
default[id]['vmail']['home'] = '/var/vmail'

# default[id]['postfix']['database']['user'] = 'postfix'

# default[id]['postfix']['map_files']['path'] = '/etc/postfix/maps'
# default[id]['postfix']['map_files']['owner'] = 'root'
# default[id]['postfix']['map_files']['group'] = 'root'
# default[id]['postfix']['map_files']['list'] = %w(
#   db_virtual_alias_maps.cf
#   db_virtual_alias_domain_maps.cf
#   db_virtual_alias_domain_catchall_maps.cf
#   db_virtual_domains_maps.cf
#   db_virtual_mailbox_maps.cf
#   db_virtual_alias_domain_mailbox_maps.cf
#   db_virtual_mailbox_limit_maps.cf
# )

default[id]['postfix']['config']['root'] = '/etc/postfix'
default[id]['postfix']['config']['owner'] = 'root'
default[id]['postfix']['config']['group'] = 'root'
default[id]['postfix']['service']['user'] = 'postfix'
default[id]['postfix']['service']['group'] = 'postfix'

default[id]['dovecot']['config']['root'] = '/etc/dovecot'
default[id]['dovecot']['config']['owner'] = 'root'
default[id]['dovecot']['config']['group'] = 'root'
default[id]['dovecot']['config']['db_file'] = 'users'
