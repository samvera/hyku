# frozen_string_literal: true

module Hyrax
  module IiifAv
    # main reasons for this decorator is to override variable names from hyrax-iiif_av
    #   solr_document => object
    #   current_ability => @ability
    #   request.base_url => hostname
    # also to remove #auth_service since it was not working for now
    module DisplaysContentDecorator
      extend ActiveSupport::Concern
      ##
      # @!group Class Attributes
      #
      # @!attribute iiif_video_url_builder [r|w]
      #   @param document [SolrDocument]
      #   @param label [String]
      #   @param host [String] (e.g. samvera.org)
      #   @return [String] the fully qualified URL.
      #
      #   @example
      #     # The below example will build a URL taht will download directly from Hyrax as the
      #     # video resource.  This is a hack to address the processing times of video derivatives;
      #     # namely in certain setups/configurations of Hyku, video processing is laggy—as in days.
      #     #
      #     # The draw back of using this method is that we're pointing to the original video file.
      #     # This is acceptable if the original file has already been processed out of band (e.g.
      #     # before uploading to Hyku/Hyrax).  When we're dealing with a raw video, this is likely
      #     # not ideal for streaming.
      #     Hyrax::IiifAv::DisplaysContent.iiif_video_url_builder = ->(document:, label:, host:) do
      #       Hyrax::Engine.routes.url_helpers.download_url(document, host:, protocol: 'https')
      #     end
      class_attribute :iiif_video_url_builder,
                      default: ->(document:, label:, host:) { Hyrax::IiifAv::Engine.routes.url_helpers.iiif_av_content_url(document.id, label:, host:) }


      class_attribute :iiif_audio_formats, default: ["ogg", "mp3"]
      # @!endgroup Class Attributes
      ##

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

      # rubocop:disable Metrics/MethodLength
      def video_display_content(_url, label = '')
        width = solr_document.width&.try(:to_i) || 320
        height = solr_document.height&.try(:to_i) || 240
        duration = conformed_duration_in_seconds
        url = iiif_video_url_builder.call(document: solr_document, label:, host: request.base_url)
        IIIFManifest::V3::DisplayContent.new(
          url,
          label:,
          width:,
          height:,
          duration:,
          type: 'Video',
          format: solr_document.mime_type
        )
      end

      def audio_display_content(_url, label = '')
        duration = conformed_duration_in_seconds
        IIIFManifest::V3::DisplayContent.new(
          Hyrax::IiifAv::Engine.routes.url_helpers.iiif_av_content_url(
            solr_document.id,
            label:,
            host: request.base_url
          ),
          label:,
          duration:,
          type: 'Sound',
          # instead of relying on the mime type of the original file, we hard code it to `audio/mpeg`
          # because this is pointing to the mp3 derivative, also UV doesn't support specifically `audio/x-wave`
          format: 'audio/mpeg'
        )
      end

        def audio_content
          streams = stream_urls
          if streams.present?
            streams.collect { |label, url| audio_display_content(url, label) }
          else
            # OVERRIDE, because we're hard coding `audio/mpeg`, it doesn't make sense to support `ogg`
            # See: https://github.com/samvera-labs/hyrax-iiif_av/blob/6273f90016c153d2add33f85cc24285d51a25382/app/presenters/concerns/hyrax/iiif_av/displays_content.rb#L118
            iiif_audio_formats.map {|fmt| audio_display_content(download_path(fmt), fmt) }
          end
        end

        def audio_display_content(_url, label = '')
          duration = conformed_duration_in_seconds
          IIIFManifest::V3::DisplayContent.new(
            Hyrax::IiifAv::Engine.routes.url_helpers.iiif_av_content_url(
              solr_document.id,
              label: label,
              host: request.base_url
            ),
            label: label,
            duration: duration,
            type: 'Sound',
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
>>>>>>> hyrax-5-upgrade
    end
  end
end

Hyrax::IiifAv::DisplaysContent.prepend(Hyrax::IiifAv::DisplaysContentDecorator)
