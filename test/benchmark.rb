#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../../../../config/environment"

require 'action_pack'
puts "Rails: #{ActionPack::VERSION::STRING}"

require 'rbench'
require 'ostruct'
 
class FauxRequest < OpenStruct
  def path   ; '/posts/1/edit.xml' ; end
  def method ; :get                ; end
end

REQUEST = FauxRequest.new
PostsController = Class.new
 
RailsRouter = ActionController::Routing::RouteSet.new
MerbRouter = ActionController::Routing::MerbRoutingWrapper.new

def letters_for_number(i)
  i.to_s.split('').map{ |i| ('a'..'z').to_a[i.to_i] }.join('')
end

$VERBOSE = nil
 
RBench.run(1) do
  column :merb
  column :rails

  [
    { :resources => 1, :subresources => 0, :compile_iterations => 100, :recognize_iterations => 10000, :generation_iterations => 10000},
    { :resources => 10, :subresources => 0, :compile_iterations => 10, :recognize_iterations => 10000, :generation_iterations => 10000 },
    { :resources => 10, :subresources => 10, :compile_iterations => 1, :recognize_iterations => 1000, :generation_iterations => 10000 },
    { :resources => 20, :subresources => 20, :compile_iterations => 1, :recognize_iterations => 100, :generation_iterations => 10000 },
    { :resources => 100, :subresources => 0, :compile_iterations => 1, :recognize_iterations => 1000, :generation_iterations => 10000 },
    { :resources => 100, :subresources => 5, :compile_iterations => 1, :recognize_iterations => 100, :generation_iterations => 10000 },
    { :resources => 5, :subresources => 100, :compile_iterations => 1, :recognize_iterations => 100, :generation_iterations => 10000 },
    { :resources => 500, :subresources => 0, :compile_iterations => 1, :recognize_iterations => 10, :generation_iterations => 10000 }
  ].each do |options|
    group "#{options[:resources]} resources, #{options[:subresources]} nested resources" do
      report "Compile (x#{options[:compile_iterations]})", options[:compile_iterations] do
        rails do
          RailsRouter.draw do |map|
            (1..(options[:resources] - 1)).each do |i|
              map.resources "postsouter#{letters_for_number(i)}" do |sub|
                (1..options[:subresources]).each do |j|
                  sub.resources "postsinner#{letters_for_number(j)}"
                end
              end
            end
  
            map.resources :posts
            map.connect ':controller/:action/:id'
            map.connect ':controller/:action/:id.:format'
          end
        end
  
        merb do
          Merb::Router.prepare do
            (1..(options[:resources] - 1)).each do |i|
              resources "postsouter#{letters_for_number(i)}" do |sub|
                (1..options[:subresources]).each do |j|
                  sub.resources "postsinner#{letters_for_number(j)}"
                end
              end
            end
  
            resources :posts
            default_routes
          end
        end
      end
  
      report "Recognize (x#{options[:recognize_iterations]})", options[:recognize_iterations] do
        rails { RailsRouter.recognize(REQUEST) }
        merb  { MerbRouter.recognize(REQUEST) }
      end

      report "person_path (x#{options[:generation_iterations]})", options[:generation_iterations] do
        ActionController::Routing::Routes = RailsRouter
        rails_helper_class = Class.new
        rails_helper_class.send(:include, ActionController::UrlWriter)
        RailsRouter.install_helpers(rails_helper_class)
        rails_helper = rails_helper_class.new
        rails { rails_helper.send(:post_path, 1) }

        ActionController::Routing::Routes = MerbRouter
        merb_helper_class = Class.new
        merb_helper_class.send(:include, ActionController::UrlWriter)
        MerbRouter.install_helpers(merb_helper_class)
        merb_helper = merb_helper_class.new
        merb  { merb_helper.send(:post_path, 1) }
      end

      report "url_for (x#{options[:generation_iterations]})", options[:generation_iterations] do
        ActionController::Routing::Routes = RailsRouter
        rails_helper_class = Class.new
        rails_helper_class.send(:include, ActionController::UrlWriter)
        RailsRouter.install_helpers(rails_helper_class)
        rails_helper = rails_helper_class.new
        rails { rails_helper.send(:url_for, :controller => 'posts', :action => 'show', :id => 1, :host => 'www.example.com') }

        ActionController::Routing::Routes = MerbRouter
        merb_helper_class = Class.new
        merb_helper_class.send(:include, ActionController::UrlWriter)
        MerbRouter.install_helpers(merb_helper_class)
        merb_helper = merb_helper_class.new
        merb  { merb_helper.send(:url_for, :controller => 'posts', :action => 'show', :id => 1, :host => 'www.example.com') }
      end

    end
  end
end
