# frozen_string_literal: true

# OVERRIDE here to add featured collection methods and to delegate collection presenters to the member presenter factory
# OVERRIDE: Hyrax 3.4.0 to add Hyrax IIIF AV

module Hyku
  class WorkShowPresenter < Hyrax::WorkShowPresenter
    # Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::FileSetPresenter
    # Adds behaviors for hyrax-iiif_av plugin.
    include Hyrax::IiifAv::DisplaysIiifAv
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::IiifAv::IiifFileSetPresenter

    delegate :title_or_label, :extent, to: :solr_document

    # OVERRIDE Hyrax v2.9.0 here to make featured collections work
    delegate :collection_presenters, to: :member_presenter_factory

    # assumes there can only be one doi
    def doi
      doi_regex = %r{10\.\d{4,9}\/[-._;()\/:A-Z0-9]+}i
      doi = extract_from_identifier(doi_regex)
      doi&.join
    end

    # unlike doi, there can be multiple isbns
    def isbns
      isbn_regex = /((?:ISBN[- ]*13|ISBN[- ]*10|)\s*97[89][ -]*\d{1,5}[ -]*\d{1,7}[ -]*\d{1,6}[ -]*\d)|
                    ((?:[0-9][-]*){9}[ -]*[xX])|(^(?:[0-9][-]*){10}$)/x
      isbns = extract_from_identifier(isbn_regex)
      isbns&.flatten&.compact
    end

    # OVERRIDE here for featured collection methods
    # Begin Featured Collections Methods
    def collection_featurable?
      user_can_feature_collection? && solr_document.public?
    end

    def display_feature_collection_link?
      collection_featurable? && FeaturedCollection.can_create_another? && !collection_featured?
    end

    def display_unfeature_collection_link?
      collection_featurable? && collection_featured?
    end

    def collection_featured?
      # only look this up if it's not boolean; ||= won't work here
      if @collection_featured.nil?
        @collection_featured = FeaturedCollection.where(collection_id: solr_document.id).exists?
      end
      @collection_featured
    end

    def user_can_feature_collection?
      current_ability.can?(:create, FeaturedCollection)
    end
    # End Featured Collections Methods

    # @return [Boolean] render a IIIF viewer
    def iiif_viewer?
      Hyrax.config.iiif_image_server? &&
        representative_id.present? &&
        representative_presenter.present? &&
        iiif_media? &&
        members_include_viewable?
    end

    private

      def iiif_media?(presenter: representative_presenter)
        presenter.image? || presenter.video? || presenter.audio? || presenter.pdf?
      end

      def members_include_viewable?
        file_set_presenters.any? do |presenter|
          iiif_media?(presenter: presenter) && current_ability.can?(:read, presenter.id)
        end
      end

      def extract_from_identifier(rgx)
        if solr_document['identifier_tesim'].present?
          ref = solr_document['identifier_tesim'].map do |str|
            str.scan(rgx)
          end
        end
        ref
      end
  end
end
