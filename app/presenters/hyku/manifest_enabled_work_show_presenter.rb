module Hyku
  class ManifestEnabledWorkShowPresenter < Hyrax::WorkShowPresenter
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyku::FileSetPresenter

    delegate :extent, :rendering_ids, to: :solr_document

    def manifest_url
      manifest_helper.polymorphic_url([:manifest, self])
    end

    def manifest_extras
      {
          sequence_rendering: sequence_rendering
      }
    end

    private

      def manifest_helper
        @manifest_helper ||= ManifestHelper.new(request.base_url)
      end

    # IIIF rendering linking properties for inclusion in the manifest
    #
    # @return [Array] array of rendering hashes
    def sequence_rendering
      renderings = []
      if solr_document.rendering_ids.present?
        solr_document.rendering_ids.map do |id|
          renderings << rendering_helper(id)
        end
      end
      renderings.flatten
    end

    def rendering_helper(id)
        ActiveFedora::SolrService.query("id:#{id}",
                                        fl: [ActiveFedora.id_field, 'label_ssi', 'mime_type_ssi'],
                                        rows: 1).map do |x|
          { '@id' => request.base_url +
            Hyrax::Engine.routes.url_helpers.download_path(x.fetch(ActiveFedora.id_field)),
            'format' => x.fetch('mime_type_ssi'),
            'label' => "Download whole resource: #{x.fetch('label_ssi')}" }
        end
      end
  end
end
