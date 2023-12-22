# frozen_string_literal: true

module OAI
  module Provider
    module ModelDecorator
      # Map Qualified Dublin Core (Terms) fields to PALNI/PALCI fields
      # rubocop:disable Metrics/MethodLength
      def map_oai_hyku
        {
          abstract: :abstract,
          access_right: :access_right,
          alternative_title: :alternative_title,
          based_near: :based_near,
          bibliographic_citation: :bibliographic_citation,
          contributor: :contributor,
          creator: :creator,
          date_created: :date_created,
          date_modified: :date_modified,
          date_uploaded: :date_uploaded,
          depositor: :depositor,
          description: :description,
          identifier: :identifier,
          keyword: :keyword,
          language: :language,
          license: :license,
          owner: :owner,
          publisher: :publisher,
          related_url: :related_url,
          resource_type: :resource_type,
          rights_notes: :rights_notes,
          rights_statement: :rights_statement,
          source: :source,
          subject: :subject,
          title: :title
        }
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end

OAI::Provider::Model.prepend(OAI::Provider::ModelDecorator)
