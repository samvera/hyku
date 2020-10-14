# frozen_string_literal: true

namespace :zookeeper do
  desc 'Push solr configs into zookeeper'
  task upload: [:environment] do
    SolrConfigUploader.default.upload(Settings.solr.configset_source_path)
  end

  desc 'Delete solr configs from zookeeper'
  task delete_all: [:environment] do
    SolrConfigUploader.default.delete_all
  end
end
