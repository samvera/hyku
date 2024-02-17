# frozen_string_literal: true

# OVERRIDE here to add featured collection methods and to delegate collection presenters to the member presenter factory
# OVERRIDE: Hyrax 5.0.0rc2 to add Hyrax IIIF AV

module Hyku
  class WorkShowPresenter < Hyrax::WorkShowPresenter
    # Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::FileSetPresenter
    # Adds behaviors for hyrax-iiif_av plugin.
    include Hyrax::IiifAv::DisplaysIiifAv

    ##
    # NOTE: IIIF Print prepends a IiifPrint::WorkShowPresenterDecorator to Hyrax::WorkShowPresenter
    # However, with the above `include Hyrax::IiifAv::DisplaysIiifAv` we obliterate that logic.  So
    # we need to re-introduce that logic.
    prepend IiifPrint::TenantConfig::WorkShowPresenterDecorator

    Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::IiifAv::IiifFileSetPresenter

    delegate :title_or_label, :extent, :source, :bibliographic_citation, :date,
             :show_pdf_viewer, :show_pdf_download_button, to: :solr_document

    # OVERRIDE Hyrax v5.0.0rc2 here to make featured collections work
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

    # OVERRIDE FILE from Hyrax v2.9.0
    # @return [String] title update for GenericWork
    Hyrax::WorkShowPresenter.class_eval do
      def page_title
        if human_readable_type == "Generic Work"
          "#{title.first} | ID: #{id} | #{I18n.t('hyrax.product_name')}"
        else
          "#{human_readable_type} | #{title.first} | ID: #{id} | #{I18n.t('hyrax.product_name')}"
        end
      end
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
      @collection_featured = FeaturedCollection.where(collection_id: solr_document.id).exists? if @collection_featured.nil?
      @collection_featured
    end

    def user_can_feature_collection?
      current_ability.can?(:create, FeaturedCollection)
    end
    # End Featured Collections Methods

    def show_pdf_viewer?
      return unless Flipflop.default_pdf_viewer?
      return unless show_pdf_viewer
      return unless file_set_presenters.any?(&:pdf?)

      show_pdf_viewer.first.to_i.positive?
    end

    def show_pdf_download_button?
      return unless Hyrax.config.display_media_download_link?
      return unless file_set_presenters.any?(&:pdf?)
      return unless show_pdf_download_button

      show_pdf_download_button.first.to_i.positive?
    end

    def viewer?
      iiif_viewer? || video_embed_viewer? || show_pdf_viewer?
    end

    def parent_works(current_user = nil)
      @parent_works ||= begin
                          docs = solr_document.load_parent_docs

                          if current_user
                            docs.select { |doc| current_user.ability.can?(:read, doc) }
                          else
                            docs.select(&:public?)
                          end
                        end
    end

    def video_embed_viewer?
      extract_video_embed_presence
    end

    private

    def members_include_viewable?
      file_set_presenters.any? do |presenter|
        iiif_media?(presenter:) && current_ability.can?(:read, presenter.id)
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

    def extract_video_embed_presence
      solr_document[:video_embed_tesim]&.first&.present?
    end
  end
end
