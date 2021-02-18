id = 'email'

default[id]['vlt_tls_prefix'] = 'tls2'
default[id]['vlt_format'] = 2

default[id]['dns_forward_servers'] = %w(
  8.8.8.8
  8.8.4.4
  208.67.222.222
  208.67.220.220
)

default[id]['postgres']['version'] = '9.5'
default[id]['postgres']['host'] = '127.0.0.1'
default[id]['postgres']['port'] = 5432

default[id]['postfixadmin']['user'] = 'postfixadmin'
default[id]['postfixadmin']['group'] = 'postfixadmin'

default[id]['postfixadmin']['version'] = '2.3.8'
default[id]['postfixadmin']['url'] =
  'http://downloads.sourceforge.net/project/postfixadmin/postfixadmin/'\
  'postfixadmin-%{version}/postfixadmin-%{version}.tar.gz'
default[id]['postfixadmin']['checksum'] =
  '8969b3312935c6e94ff17508f5b7e78b65828cd52d371adde3bfd9206597d94a'

default[id]['postfixadmin']['database']['name'] = 'postfix'
default[id]['postfixadmin']['database']['user'] = 'postfixadmin'

default[id]['postfixadmin']['quota_multiplier'] = 1_048_576

default[id]['postfixadmin']['service']['pool']['max_childen'] = 5
default[id]['postfixadmin']['service']['pool']['start_servers'] = 2
default[id]['postfixadmin']['service']['pool']['min_spare_servers'] = 1
default[id]['postfixadmin']['service']['pool']['max_spare_servers'] = 3
default[id]['postfixadmin']['service']['pool']['max_requests'] = 100
default[id]['postfixadmin']['service']['php_memory_limit'] = '64M'
default[id]['postfixadmin']['service']['listen_sock'] = \
  '/var/run/php-fpm-postfixadmin.sock'

default[id]['postfixadmin']['service']['hsts_max_age'] = 15_724_800
default[id]['postfixadmin']['service']['hpkp_max_age'] = 604_800
default[id]['postfixadmin']['service']['disable_setup_page'] = false

default[id]['vmail']['uid'] = 5000
default[id]['vmail']['gid'] = 5000
default[id]['vmail']['user'] = 'vmail'
default[id]['vmail']['group'] = 'vmail'
default[id]['vmail']['home'] = '/var/vmail'
default[id]['vmail']['trashbase'] = '/var/vmail/.trash'

default[id]['postfix']['config']['root'] = '/etc/postfix'
default[id]['postfix']['config']['owner'] = 'root'
default[id]['postfix']['config']['group'] = 'root'
default[id]['postfix']['service']['user'] = 'postfix'
default[id]['postfix']['service']['group'] = 'postfix'

default[id]['postfix']['database']['user'] = 'postfix'

default[id]['postfix']['message_size_limit'] = 50 * 1024 * 1024

default[id]['dovecot']['config']['root'] = '/etc/dovecot'
default[id]['dovecot']['config']['owner'] = 'root'
default[id]['dovecot']['config']['group'] = 'root'
default[id]['dovecot']['config']['db_file'] = 'users'
default[id]['dovecot']['config']['sieve']['max_actions'] = 32
default[id]['dovecot']['config']['sieve']['max_redirects'] = 4

default[id]['dovecot']['database']['user'] = 'dovecot'

default[id]['dovecot']['quota_status']['host'] = '127.0.0.1'
default[id]['dovecot']['quota_status']['port'] = 12_340

default[id]['opendkim']['config']['root'] = '/etc/opendkim'
default[id]['opendkim']['config']['owner'] = 'root'
default[id]['opendkim']['config']['group'] = 'root'
default[id]['opendkim']['service']['user'] = 'opendkim'
default[id]['opendkim']['service']['group'] = 'opendkim'
default[id]['opendkim']['service']['host'] = '127.0.0.1'
default[id]['opendkim']['service']['port'] = 8891
default[id]['opendkim']['selector'] = 'default'
default[id]['opendkim']['domainkey'] = '_domainkey'

default[id]['postgrey']['host'] = '127.0.0.1'
default[id]['postgrey']['port'] = 10_023

default[id]['amavis']['config']['root'] = '/etc/amavis'
default[id]['amavis']['config']['owner'] = 'root'
default[id]['amavis']['config']['group'] = 'root'
default[id]['amavis']['service']['host'] = '127.0.0.1'
default[id]['amavis']['service']['port'] = 10_024
default[id]['amavis']['service']['user'] = 'amavis'
default[id]['amavis']['service']['group'] = 'amavis'
default[id]['amavis']['service']['max_servers'] = 2

default[id]['amavis']['database']['user'] = 'amavis'

default[id]['clamav']['service']['user'] = 'clamav'
default[id]['clamav']['service']['group'] = 'clamav'

default[id]['roundcube']['version'] = '1.2.0'
default[id]['roundcube']['url'] = \
  'https://github.com/roundcube/roundcubemail/releases/download/'\
  '%{version}/roundcubemail-%{version}.tar.gz'
default[id]['roundcube']['checksum'] =
  'e3b89c2772c2c5990da9bca640bc342f486edf356016cf717e6a1083c822b523'

default[id]['roundcube']['user'] = 'roundcube'
default[id]['roundcube']['group'] = 'roundcube'

default[id]['roundcube']['database']['name'] = 'roundcube'
default[id]['roundcube']['database']['user'] = 'roundcube'

default[id]['roundcube']['service']['pool']['max_childen'] = 5
default[id]['roundcube']['service']['pool']['start_servers'] = 2
default[id]['roundcube']['service']['pool']['min_spare_servers'] = 1
default[id]['roundcube']['service']['pool']['max_spare_servers'] = 3
default[id]['roundcube']['service']['pool']['max_requests'] = 100
default[id]['roundcube']['service']['php_memory_limit'] = '64M'
default[id]['roundcube']['service']['listen_sock'] = \
  '/var/run/php-fpm-roundcube.sock'
default[id]['roundcube']['service']['hsts_max_age'] = 15_724_800
default[id]['roundcube']['service']['hpkp_max_age'] = 604_800
default[id]['roundcube']['service']['enable_installer'] = true
