id = 'email'

group node[id]['vmail']['group'] do
  gid node[id]['vmail']['gid']
  action :create
end

user node[id]['vmail']['user'] do
  uid node[id]['vmail']['uid']
  group node[id]['vmail']['group']
  shell '/bin/false'
  manage_home true
  home node[id]['vmail']['home']
  action :create
end
