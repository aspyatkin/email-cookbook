id = 'email'

group node[id]['vmail']['group'] do
  action :create
end

user node[id]['vmail']['user'] do
  group node[id]['vmail']['group']
  shell '/bin/false'
  manage_home true
  home node[id]['vmail']['home']
  action :create
end
