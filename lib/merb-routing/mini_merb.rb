# this provides a basic compatibility library to merb-core
module Merb
  Config = {}
  class << self
    def logger
      RAILS_DEFAULT_LOGGER
    end
    
    def root
      RAILS_ROOT
    end
    
    def environment
      ENV['RAILS_ENV']
    end
  end

  module ControllerExceptions
    NotFound = ActionController::RoutingError
  end

  module Parse
    def self.escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*$1.size).join('%').upcase
      }.tr(' ', '+')
    end
    
    def self.params_to_query_string(value, prefix = nil)
      case value
      when Array
        value.map { |v|
          params_to_query_string(v, "#{prefix}[]")
        } * "&"
      when Hash
        value.map { |k, v|
          params_to_query_string(v, prefix ? "#{prefix}[#{escape(k)}]" : escape(k))
        } * "&"
      else
        "#{prefix}=#{escape(value)}"
      end
    end
  end
end

RAILS_DEFAULT_LOGGER.instance_eval do
  alias :debug! :debug
  alias :info! :info
  alias :error! :error
end

module Kernel
  def extract_options_from_args!(args)
    args.pop if Hash === args.last
  end
end

