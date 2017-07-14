module Hyku
  class ManifestEnabledWorkShowPresenter < Hyrax::WorkShowPresenter
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyku::FileSetPresenter

    delegate :extent, to: :solr_document

    def manifest_url
      manifest_helper.polymorphic_url([:manifest, self])
    end

    private

      def manifest_helper
        @manifest_helper ||= ManifestHelper.new(request.base_url)
      end
  end
end
