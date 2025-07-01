# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# OVERRIDE: Questioning Authority gem (qa) v5.x - Discogs::GenericAuthority
# Adds support for Discogs Personal Access Token (user token) authentication.
# If discogs_user_token is set, use it for API requests (Authorization header).
# Otherwise, fall back to key/secret in the URL (legacy, not recommended for new apps).

module Qa
  module Authorities
    module DiscogsGenericAuthorityDecorator
      def build_query_url(q, tc)
        page = nil
        per_page = nil
        if tc.params["startRecord"].present?
          page = (tc.params["startRecord"].to_i - 1) / tc.params["maxRecords"].to_i + 1
          per_page = tc.params["maxRecords"]
        else
          page = tc.params["page"]
          per_page = tc.params["per_page"]
        end
        escaped_q = ERB::Util.url_encode(q)
        url = "https://api.discogs.com/database/search?q=#{escaped_q}&type=#{tc.params['subauthority']}&page=#{page}&per_page=#{per_page}"
        unless self.class.discogs_user_token.present?
          url += "&key=#{self.class.discogs_key}&secret=#{self.class.discogs_secret}"
        end
        url
      end

      def json(url)
        if self.class.discogs_user_token.present?
          # Make HTTP request with Authorization header
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          
          request = Net::HTTP::Get.new(uri)
          request['Authorization'] = "Discogs token=#{self.class.discogs_user_token}"
          request['User-Agent'] = 'HykuApp/1.0'
          
          response = http.request(request)
          JSON.parse(response.body)
        else
          super
        end
      end

      def search(q, tc)
        # If we have a user token, proceed with search
        if self.class.discogs_user_token.present?
          response = json(build_query_url(q, tc))
          if tc.params["response_header"] == "true"
            response_hash = {}
            response_hash["results"] = parse_authority_response(response)
            response_hash["response_header"] = build_response_header(response)
            return response_hash
          end
          parse_authority_response(response)
        else
          super
        end
      end
    end
  end
end

# Add class-level accessors for user token and credentials
Qa::Authorities::Discogs::GenericAuthority.singleton_class.attr_accessor :discogs_user_token, :discogs_key, :discogs_secret

Qa::Authorities::Discogs::GenericAuthority.prepend(Qa::Authorities::DiscogsGenericAuthorityDecorator) 