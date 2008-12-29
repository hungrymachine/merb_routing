class NamedRoutesWrapper
  # the helpers are made protected by default--we make them public for
  # easier access during testing and troubleshooting.
  #NOTE: not really needed to be valid.. its a nice-to-have for testing
  def helpers
    [] 
  end
end

class ActionController::Routing::MerbRoutingWrapper
  # this setter is used by rails dispatcher but isn't actually used by us
  attr_writer :configuration_file

  def configuration_file
    "#{RAILS_ROOT}/config/router.rb"
  end

  # mixes in url(), polymorphic_path stuff, and method_missing to catch named_route_path stuff
  def install_helpers(klass)
    klass.module_eval do
      include ActionController::Routing::Helpers
      include Merb::Router::UrlHelpers
    end
  end
  
  def named_routes
     NamedRoutesWrapper.new
  end
  
  # rebuilds routes
  def reload
    return if (mtime = File.stat(configuration_file).mtime) && mtime == @routes_last_modified
    [ActionController::Base, ActionView::Base].each { |d| install_helpers(d) }
    Merb::Router.reset!
    @routes_last_modified = mtime
    @routes_by_controller = nil
    load configuration_file
  end

  # given a request object, this matches a route, sets route/path_parameters, and returns the controller class
  def recognize(request)
    request.route, request.path_parameters = Merb::Router.route_for(request)
    "#{request.path_parameters[:controller].camelize}Controller".constantize
  end

  # given a hash of params, this determines the best route for us
  def generate(options, recall={})
    merged_options = recall.merge(options).reject { |k,v| v.nil? }

    if options[:use_route]
      best_route = Merb::Router.named_routes[options.delete(:use_route)]
    else
      best_route = nil
      best_score = 0
    
      routes_for_controller_and_action(merged_options[:controller], merged_options[:action]).map do |route|
        score = route.params.reject { |k,v| !((v =~ /^"(.*)"$/ && merged_options[k] == $1) || (v =~ /^\((.*)\)$/ && merged_options.has_key?(k))) }.length
        best_score, best_route = score, route if score > best_score
      end
    end

    keys_we_dont_need = best_route.params.reject { |k,v| !(v =~ /^"(.*)"$/ && merged_options[k] == $1) }.keys
    nonredundant_options = options.reject { |k,v| keys_we_dont_need.include?(k) }

    best_route.generate([nonredundant_options], recall)
  end

  def routes_for_controller_and_action(controller, action)
    @routes_by_controller ||= {}
    @routes_by_controller[controller] ||= {}
    @routes_by_controller[controller][action] ||= Merb::Router.routes.reject { |route| (route.params[:controller] =~ /^"(.*)"$/ && $1 != controller) || (route.params[:action] =~ /^"(.*)"$/ && $1 != action) }
  end
end

# automatically use :to_params or :id on active record objects
Merb::Router::Route.class_eval do
  def identifier_for_with_active_record(obj)
    case
      when obj.respond_to?(:to_param) then :to_param
      when obj.is_a?(ActiveRecord::Base) then :id
      else identifier_for_without_active_record(obj)
    end
  end
  alias_method_chain :identifier_for, :active_record
end

# set the Routes object to our wrapper
silence_warnings { ActionController::Routing::Routes = ActionController::Routing::MerbRoutingWrapper.new }

# merb calls request.uri sometimes... map it to request_uri
ActionController::AbstractRequest.class_eval { alias :uri :request_uri }
  
# store the route we ended up recognizing so we can use url(:this)
ActionController::AbstractRequest.class_eval { attr_accessor :route }
