# this translates url_for, polymorphic_path, and rails named routes into merb routes
module Merb::Router::UrlHelpers
  def url(name, *args)
    args << params
    name = request.route if name == :this
    Merb::Router.url(name, *args)
  end

  def method_missing_with_merb_routing(method_id, *args)
    if /^(formatted_)?(.*)(_url|_path)$/.match(method_id.to_s)
      options, args = args.last.is_a?(Hash) ? [args.pop, args] : [{}, args]
      
      if $1 == 'formatted_'
        options[:format] = args.pop
      end

      host_prefix = ""
      if $3 == '_url' || options.delete(:only_path) == false
        # logic copied from ActionController::UrlRewriter... no support for https (options[:protocol])
        host_prefix << "http://"
        host_prefix << "#{CGI.escape(options.delete(:user))}:#{CGI.escape(options.delete(:password))}@" if options[:user] && options[:password]
        host_prefix << (options.delete(:host) || request.host_with_port)
        host_prefix << ":#{options.delete(:port)}" if options.key?(:port)
      end
      
      return host_prefix + Merb::Router.url($2.to_sym, *(args << options << {}))
    else
      method_missing_without_merb_routing(method_id, *args)
    end
  end
  alias_method_chain :method_missing, :merb_routing
end