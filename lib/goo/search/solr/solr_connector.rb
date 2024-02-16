require 'rsolr'
require_relative 'solr_schema_generator'
require_relative 'solr_schema'
require_relative 'solr_admin'
require_relative 'solr_query'

module SOLR

  class SolrConnector
    include Schema, Administration, Query
    attr_reader :solr

    def initialize(solr_url, collection_name)
      @solr_url = solr_url
      @collection_name = collection_name
      @solr = RSolr.connect(url: collection_url)
      @custom_schema = false
    end

    def init(force = false)
      return if collection_exists?(@collection_name) && !force

      create_collection

      init_schema
    end

  end
end

