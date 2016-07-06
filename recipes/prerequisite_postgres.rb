id = 'email'

node.default['postgresql']['version'] = node[id]['postgres']['version']
node.default['postgresql']['enable_pgdg_apt'] = true
node.default['postgresql']['server']['packages'] = [
  "postgresql-#{node[id]['postgres']['version']}",
  "postgresql-server-dev-#{node[id]['postgres']['version']}"
]
node.default['postgresql']['contrib']['packages'] = [
  "postgresql-contrib-#{node[id]['postgres']['version']}"
]
node.default['postgresql']['client']['packages'] = [
  "postgresql-client-#{node[id]['postgres']['version']}",
  'libpq-dev'
]
node.default['postgresql']['dir'] = \
  "/etc/postgresql/#{node[id]['postgres']['version']}/main"
node.default['postgresql']['config']['listen_addresses'] = \
  node[id]['postgres']['host']
node.default['postgresql']['config']['port'] = \
  node[id]['postgres']['port']

require 'digest/md5'

postgres_root_username = ChefCookbook::Email.postgres_root_username
helper = ChefCookbook::Email.new node

postgres_pwd_digest = ::Digest::MD5.hexdigest(
  "#{helper.postgres_user_password(postgres_root_username)}"\
  "#{postgres_root_username}"
)
node.default['postgresql']['password'][postgres_root_username] = \
  "md5#{postgres_pwd_digest}"

include_recipe 'postgresql::server'
include_recipe 'postgresql::client'
include_recipe 'database::postgresql'
