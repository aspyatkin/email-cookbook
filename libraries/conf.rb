module Email
  module Conf
    def self.value(value)
      case value
      when TrueClass then "'YES'"
      when FalseClass then "'NO'"
      else
        Email::PHP.ruby_value_to_php(value) || "'#{value}'"
      end
    end
  end
end
