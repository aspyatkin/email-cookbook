module Email
  module Helper
    def postgres_root_username
      'postgres'
    end

    module_function :postgres_root_username

    def postgres_connection_info
      id = 'email'

      {
        host: node[id]['postgres']['listen']['address'],
        port: node[id]['postgres']['listen']['port'],
        username: postgres_root_username,
        password: data_bag_item('postgres', node.chef_environment)['credentials'][postgres_root_username]
      }
    end
  end
end
