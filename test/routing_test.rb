#!/usr/bin/env ruby

require 'rubygems'
require 'active_record'
require 'active_support'
require 'action_controller'
require 'mocha'
require 'test/unit'

require 'ostruct'
[:method, :to_param].each { |sym| OpenStruct.class_eval "def #{sym}; @table[#{sym.inspect}]; end"}

RAILS_DEFAULT_LOGGER = ActiveSupport::BufferedLogger.new(STDERR)

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib/"
require "merb-routing"

class Person; end
class Entity; end
class Blog; end
class PeopleController; end

class MerbRoutingTests < Test::Unit::TestCase
  def setup
    Merb::Router.reset!
  end

  def test_basic_resource
    Merb::Router.prepare { resources :people }
    request = OpenStruct.new(:path => '/people/1/edit', :method => :get)
    assert_equal ActionController::Routing::Routes.recognize(request), PeopleController
    assert_equal request.path_parameters[:controller], 'people'
    assert_equal request.path_parameters[:action], 'edit'
    assert_equal request.path_parameters[:id], '1'
  end

  def test_named_helpers_takes_a_hash
    Merb::Router.prepare do
      resources :people do |people|
        people.resources :entities, :collection => { :listing => :get }
      end
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new

    assert_equal "/people/1/entities/listing?ref=collection-detail-link", obj.listing_person_entities_path(:person_id => 1, :ref => "collection-detail-link")
  end

  def test_named_helpers_takes_anonymous_params
    Merb::Router.prepare do
      resources :people do |people|
        people.resources :entities, :collection => { :listing => :get }
      end
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new

    assert_equal "/people/1/entities/listing?ref=collection-detail-link", obj.listing_person_entities_path(1, :ref => "collection-detail-link")
  end

  def test_named_helpers_takes_objects
    Merb::Router.prepare do
      resources :people do |people|
        people.resources :entities, :collection => { :listing => :get }
      end
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new

    assert_equal "/people/1-bob-dole/entities/listing?ref=collection-detail-link", obj.listing_person_entities_path(OpenStruct.new(:to_param => '1-bob-dole'), :ref => "collection-detail-link")
    assert_equal "/people/1-bob-dole/entities/listing?ref=collection-detail-link", obj.listing_person_entities_path(:person_id => OpenStruct.new(:to_param => '1-bob-dole'), :ref => "collection-detail-link")
  end
  
  def test_singular_resource
    Merb::Router.prepare do
      resources :blog
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new

    assert_equal "/blog", obj.blog_index_path
  end
  
  def test_method_any
    Merb::Router.prepare do
      resources :people, :member => { :some_method => :any }
    end

    request = OpenStruct.new(:path => '/people/1/some_method', :method => :get)
    assert_equal ActionController::Routing::Routes.recognize(request), PeopleController
  end

  def test_formatted_routes_work
    Merb::Router.prepare do
      resources :people, :member => { :some_method => :any }
    end

    request = OpenStruct.new(:path => '/people/1/some_method.xml', :method => :get)
    assert_equal ActionController::Routing::Routes.recognize(request), PeopleController
    assert_equal request.path_parameters[:format], "xml"
  end

  def test_formatted_helpers_work
    Merb::Router.prepare do
      resources :people do |people|
        people.resources :entities, :collection => { :listing => :get }
      end
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new
  
    assert_equal "/people/1/entities/listing.xml", obj.formatted_listing_person_entities_path(1, :xml)
  end

  def test_formatted_helpers_work_with_options
    Merb::Router.prepare do
      resources :people do |people|
        people.resources :entities, :collection => { :listing => :get }
      end
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new
  
    assert_equal "/people/1/entities/listing.xml?ref=collection-detail-link", obj.formatted_listing_person_entities_path(1, :xml, :ref => "collection-detail-link")
  end

  def test_formatted_helpers_work_with_host
    Merb::Router.prepare do
      resources :people do |people|
        people.resources :entities, :collection => { :listing => :get }
      end
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new
  
    assert_equal "http://www.myhost.com/people/1/entities/listing.xml?ref=collection-detail-link", obj.formatted_listing_person_entities_path(1, :xml, :ref => "collection-detail-link", :only_path => false, :host => 'www.myhost.com')
  end

  def test_external_path
    Merb::Router.prepare do
      resources :external_people, :member => { :verify_email_address => :get }
    end
      
    helper_container = Class.new
    ActionController::Routing::Routes.install_helpers(helper_container)
    obj = helper_container.new
  
    assert_equal "http://external.host/external_people/1/verify_email_address?token=sometoken", obj.verify_email_address_external_person_path(:id => 1, :token => 'sometoken', :only_path => false, :host => 'external.host')
  end
end
