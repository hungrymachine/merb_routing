module Rake
  module TaskManager
    def redefine_task(task_class, args, &block)
      task_name, deps = (RAKEVERSION >= '0.8.0') ? resolve_args([args]) : resolve_args(args)
      task_name = task_class.scope_name(@scope, task_name)
      deps = [deps] unless deps.respond_to?(:to_ary)
      deps = deps.collect {|d| d.to_s }
      task = @tasks[task_name.to_s] = task_class.new(task_name, self)
      task.application = self
      if RAKEVERSION >= '0.8.0'
        task.add_description(@last_description)
        @last_description = nil
      else
        task.add_comment(@last_comment)
        @last_comment = nil
      end
      task.enhance(deps, &block)
      task
    end
  end
  class Task
    class << self
      def redefine_task(args, &block)
        Rake.application.redefine_task(self, args, &block)
      end
    end
  end
end

def redefine_task(args, &block)
  Rake::Task.redefine_task(args, &block)
end


desc 'Print out all defined routes in match order, with names.'
redefine_task :routes do
  Rake::Task[:environment].invoke
  routes = Merb::Router.routes.map do |route|
    { :name => route.name.to_s, :verb => (route.conditions[:method] || '').upcase, :segs => route.to_s, :reqs => route.params.reject { |k,v| k == :path || v =~ /\(.*\)/ }.inspect.gsub('\"',''), :conditions => route.conditions.reject { |k,v| k == :method || k == :path }.inspect }
  end

  name_width = routes.collect {|r| r[:name]}.collect {|n| n.length}.max
  verb_width = routes.collect {|r| r[:verb]}.collect {|v| v.length}.max
  segs_width = routes.collect {|r| r[:segs]}.collect {|s| s.length}.max
  routes.each do |r|
    puts "#{r[:name].rjust(name_width)} #{r[:verb].ljust(verb_width)} #{r[:segs].ljust(segs_width)} #{r[:reqs]} #{r[:conditions] unless r[:conditions] == '{}'}"
  end
end
