module ChefCookbook
  class Email
    def initialize(node)
      @node = node
    end

    def self.postgres_root_username
      'postgres'
    end

    def postgres_user_password(username)
      ::Chef::EncryptedDataBagItem.load(
        'postgres',
        @node.chef_environment
      )['credentials'].fetch(username, nil)
    end

    def postgres_connection_info
      id = 'email'
      root_username = self.class.postgres_root_username

      {
        host: @node[id]['postgres']['host'],
        port: @node[id]['postgres']['port'],
        username: root_username,
        password: postgres_user_password(root_username)
      }
    end

    def postfixadmin_setup_password
      require 'digest/sha1'
      salt = ::Chef::EncryptedDataBagItem.load(
        'postfixadmin',
        @node.chef_environment
      )['admin_credentials']['salt']
      password = ::Chef::EncryptedDataBagItem.load(
        'postfixadmin',
        @node.chef_environment
      )['admin_credentials']['password']

      "#{salt}:#{::Digest::SHA1.hexdigest("#{salt}:#{password}")}"
    end
  end
end
