# frozen_string_literal: true

module Hyku
  module S3Migration
    # One JSON object per migrated file set under PREFIX in the repository bucket, so parallel
    # jobs never share a buffer and a crashed job loses nothing.
    class Manifest
      PREFIX = '_migration-manifests/'

      def initialize(client: nil, bucket: nil)
        @client = client || self.class.default_client
        @bucket = bucket || ENV.fetch('REPOSITORY_S3_BUCKET')
      end

      def self.default_client
        options = { region: ENV.fetch('REPOSITORY_S3_REGION', 'us-east-1') }
        if ENV['REPOSITORY_S3_ACCESS_KEY'].present?
          options[:access_key_id] = ENV['REPOSITORY_S3_ACCESS_KEY']
          options[:secret_access_key] = ENV['REPOSITORY_S3_SECRET_KEY']
        end
        Aws::S3::Client.new(**options)
      end

      def write(entry)
        client.put_object(bucket:, key: key_for(entry.fetch(:file_set_id)), body: entry.to_json)
      end

      def read(file_set_id)
        parse(client.get_object(bucket:, key: key_for(file_set_id)))
      rescue Aws::S3::Errors::NoSuchKey
        nil
      end

      def each_entry
        return enum_for(:each_entry) unless block_given?

        client.list_objects_v2(bucket:, prefix: PREFIX).each do |page|
          page.contents.each { |object| yield parse(client.get_object(bucket:, key: object.key)) }
        end
      end

      private

      attr_reader :client, :bucket

      def key_for(file_set_id)
        "#{PREFIX}#{file_set_id}.json"
      end

      def parse(response)
        JSON.parse(response.body.read, symbolize_names: true)
      end
    end
  end
end
