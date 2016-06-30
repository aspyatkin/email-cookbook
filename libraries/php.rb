module Email
  module PHP
    def encrypt_setup_password(password, salt)
      require 'digest/sha1'

      "#{salt}:#{::Digest::SHA1.hexdigest("#{salt}:#{password}")}"
    end

    def self.ruby_value_to_php(value)
      case value
      when nil then 'NULL'
      when Fixnum, Float then v
      when Array then Email::PHP.array(v)
      when Hash then Email::PHP.hash(v)
      end
    end

    def self.php_from_template(template, obj)
      eruby = Erubis::Eruby.new(template)
      eruby.evaluate(obj: obj, Email_Conf: Email::Conf)
    end

    def self.array(ary)
      template =
        'array(<%=
          list = @obj.kind_of?(Array) ? @obj : [ @obj ]
          list.map do |item|
            @Email_Conf.value(item)
          end.join(", ")
        %>)'
      php_from_template(template, ary)
    end

    def self.hash(hs)
      template =
        'array(<%=
          @obj.to_hash.sort.map do |k, v|
            "#{@Email_Conf.value(v)} => #{@Email_Conf.value(k)}"
          end.join(", ")
        %>)'
      php_from_template(template, hs)
    end
  end
end
