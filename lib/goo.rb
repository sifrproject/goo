require "pry"
require "rdf"
require "rdf/ntriples"
require "sparql/client"

require "set"
require "uri"
require "uuid"
require 'rsolr'

require_relative "goo/sparql/sparql"
require_relative "goo/base/base"
require_relative "goo/validators/enforce"
#require_relative "goo/search/search"
#require_relative "goo/naming/naming"
require_relative "goo/utils/utils"

module Goo
  
  @@resource_options = Set.new([:persistent]).freeze

  @@configure_flag = false
  @@sparql_backends = {}
  @@search_backends = {}
  @@model_by_name = {}
  @@search_connection = nil

  @@default_namespace = nil
  @@namespaces = {}

  def self.add_namespace(shortcut, namespace,default=false)
    if !(namespace.instance_of? RDF::Vocabulary)
      raise ArgumentError, "Namespace must be a RDF::Vocabulary object" 
    end
    @@namespaces[shortcut.to_sym] = namespace
    @@default_namespace = shortcut if default
  end

  def self.add_sparql_backend(name, *opts)
    opts = opts[0]
    @@sparql_backends[name] = opts
    @@sparql_backends[name][:query]=Goo::SPARQL::Client.new(opts[:query], {protocol: "1.1"})
    @@sparql_backends[name][:update]=Goo::SPARQL::Client.new(opts[:update], {protocol: "1.0"})
    @@sparql_backends[name][:data]=Goo::SPARQL::Client.new(opts[:data], {protocol: "1.1"})
  end

  def self.add_search_backend(name, *opts)
    opts = opts[0]
    unless opts.include? :service
      raise ArgumentError, "Search backend configuration must contains a host list."
    end
    @@search_backends[name] = opts
  end

  def self.configure_sanity_check()
    unless @@namespaces.length > 0
      raise ArgumentError, "Namespaces needs to be provided."
    end
    unless @@default_namespace
      raise ArgumentError, "Default namespaces needs to be provided."
    end
  end

  def self.configure
    if not block_given?
      raise ArgumentError, "Configuration needs to receive a code block"
    end
    yield self 
    configure_sanity_check()
    if @@search_backends.length > 0
      @@search_connection = RSolr.connect :url => search_conf()
    end
    @@namespaces.freeze
    @@sparql_backends.freeze
    @@search_backends.freeze
    @@configure_flag = true
  end

  def self.configure?
    return @@configure_flag
  end

  def self.namespaces
    return @@namespaces
  end

  def self.search_conf
    return @@search_backends[:main][:service]
  end

  def self.search_connection
    return @@search_connection
  end

  def self.sparql_query_client(name=:main)
    return @@sparql_backends[name][:query]
  end

  def self.sparql_update_client(name=:main)
    return @@sparql_backends[name][:update]
  end

  def self.sparql_data_client(name=:main)
    return @@sparql_backends[name][:data]
  end

  def self.add_model(name, model)
    @@model_by_name[name] = model
  end

  def self.model_by_name(name)
    return @@model_by_name[name]
  end

  def self.resource_options
    return @@resource_options
  end

  def self.vocabulary(namespace)
    return @@namespaces[@@default_namespace] if namespace.nil?
    return @@namespaces[namespace] 
  end

end

#require_relative "goo/validators/validators"
