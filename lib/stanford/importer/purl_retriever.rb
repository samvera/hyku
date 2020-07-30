# frozen_string_literal: true

module Stanford
  module Importer
    class PurlRetriever
      def self.get(druid)
        new(druid).get
      end

      def initialize(druid)
        @druid = druid
      end

      def get
        conn.get(path).body
      end

      private

        def path
          "/#{@druid}.xml"
        end

        def conn
          @conn ||= Faraday.new(url: 'https://purl.stanford.edu') do |faraday|
            faraday.adapter :httpclient
            faraday.use Faraday::Response::RaiseError # raise exceptions on 40x, 50x responses
          end
        end
    end
  end
end
