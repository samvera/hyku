# frozen_string_literal: true

module Hyrax
  module IiifAv
    # main reasons for this decorator is to override variable names from hyrax-iiif_av
    #   solr_document => object
    #   current_ability => @ability
    #   request.base_url => hostname
    # also to remove #auth_service since it was not working for now
    module DisplaysContentDecorator
      def solr_document
        defined?(super) ? super : object
      end

      def current_ability
        defined?(super) ? super : @ability
      end

      Request = Struct.new(:base_url, keyword_init: true)

      def request
        Request.new(base_url: hostname)
      end

      private

      def image_content
        return nil unless latest_file_id
        url = Hyrax.config.iiif_image_url_builder.call(
          latest_file_id,
          request.base_url,
          Hyrax.config.iiif_image_size_default,
          solr_document.mime_type
        )

        # Serving up only prezi 3
        image_content_v3(url)
      end

      ##
      # @note In the case where we have stream_urls, we'll assume the URL is correct.  In the case
      #       where we're deferring to the document, we'll use {Hyku::Application.iiif_video_labels_and_mime_types}
      def video_content
        # @see https://github.com/samvera-labs/iiif_manifest
        streams = stream_urls
        if streams.present?
          streams.collect { |label, url| video_display_content(url, label) }
        else
          Hyku::Application.iiif_video_labels_and_mime_types.map do |label, mime_type|
            url = Hyku::Application.iiif_av_url_builder.call(document: solr_document, label:, host: request.base_url, mime_type:)
            video_display_content(url, label, mime_type:)
          end
        end
      end

      # rubocop:disable Metrics/MethodLength
      def video_display_content(url, label = '', mime_type: solr_document.mime_type)
        width = solr_document.width&.try(:to_i) || 320
        height = solr_document.height&.try(:to_i) || 240
        duration = conformed_duration_in_seconds
        IIIFManifest::V3::DisplayContent.new(
          url,
          label:,
          width:,
          height:,
          duration:,
          type: 'Video',
          format: mime_type
        )
      end

      ##
      # @note In the case where we have stream_urls, we'll assume the URL is correct.  In the case
      #       where we're deferring to the document, we'll use {Hyku::Application.iiif_audio_labels_and_mime_types}
      def audio_content
        streams = stream_urls
        if streams.present?
          streams.collect { |label, url| audio_display_content(url, label) }
        else
          Hyku::Application.iiif_audio_labels_and_mime_types.map do |label, mime_type|
            url = Hyku::Application.iiif_av_url_builder.call(document: solr_document, label:, host: request.base_url, mime_type:)
            audio_display_content(url, label, mime_type:)
          end
        end
      end

      def audio_display_content(url, label = '', mime_type: solr_document.mime_type)
        duration = conformed_duration_in_seconds
        IIIFManifest::V3::DisplayContent.new(
          url,
          label:,
          duration:,
          type: 'Sound',
          format: mime_type
        )
      end

      def conformed_duration_in_seconds
        if Array(solr_document.duration)&.first&.count(':') == 3
          # takes care of milliseconds like ["0:0:01:001"]
          Time.zone.parse(Array(solr_document.duration).first.sub(/.*\K:/, '.')).seconds_since_midnight
        elsif Array(solr_document.duration)&.first&.include?(':')
          # if solr_document.duration evaluates to something like ["0:01:00"] which will get converted to seconds
          Time.zone.parse(Array(solr_document.duration).first).seconds_since_midnight
        else
          # handles cases if solr_document.duration evaluates to something like ['25 s']
          Array(solr_document.duration).first.try(:to_f)
        end ||
          400.0
      end
    end
  end
end

Hyrax::IiifAv::DisplaysContent.prepend(Hyrax::IiifAv::DisplaysContentDecorator)
