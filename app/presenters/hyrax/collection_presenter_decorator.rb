# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0
# - Add collection methods to collection presenter and override to return
#   full banner_file data, rather than only download path to file.
# - Alter permissions-related behavior.
# Terms is the list of fields displayed by app/views/collections/_show_descriptions.html.erb
module Hyrax
  module CollectionPresenterDecorator
    extend ActiveSupport::Concern

    class_methods do
      def terms
        # OVERRIDE Hyrax - removed size
        super - [:size]
      end

      def primary_terms
        %i[title description collection_subtitle]
      end
    end

    delegate :collection_subtitle, to: :solr_document

    # Add new method to check if a user has permissions to create any works.
    # This is used to restrict who can deposit new works through collections.
    #
    # @see app/views/hyrax/dashboard/collections/_show_add_items_actions.html.erb
    def create_any_work_types?
      create_work_presenter.authorized_models.any?
    end

    # OVERRIDE Hyrax - remove size
    def [](key)
      case key
      when :total_items
        total_items
      else
        solr_document.send key
      end
    end

    # OVERRIDE: Add label for Edit access
    #
    # For the Managed Collections tab, determine the label to use for the level of access
    # the user has for this admin set. Checks from most permissive to most restrictive.
    # @return String the access label (e.g. Manage, Deposit, View)
    def managed_access
      # OVERRIDE: Change check for manage access from :edit to :destroy
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.manage') if current_ability.can?(:destroy, solr_document)
      # OVERRIDE: Add label for Edit access
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.edit') if current_ability.can?(:edit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.deposit') if current_ability.can?(:deposit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.view') if current_ability.can?(:read, solr_document)
      ''
    end

    # OVERRIDE: Because the only batch operation allowed currently is deleting,
    # change the ability check because not all users who can edit can also destroy.
    #
    # Determine if the user can perform batch operations on this collection.  Currently, the only
    # batch operation allowed is deleting, so this is equivalent to checking if the user can delete
    # the collection determined by criteria...
    # * user must be able to edit the collection to be able to delete it
    # * the collection does not have to be empty
    # @return Boolean true if the user can perform batch actions; otherwise, false
    def allow_batch?
      return true if current_ability.can?(:destroy, solr_document) # OVERRIDE: change :edit to :destroy
      false
    end

    # override banner_file in hyrax to include all banner information rather than just relative_path
    def banner_file
      @banner_file ||= begin
                         # Find Banner filename
                         banner_info = CollectionBrandingInfo.where(collection_id: id, role: "banner")
                         filename = File.split(banner_info.first.local_path).last unless banner_info.empty?
                         alttext = banner_info.first.alt_text unless banner_info.empty?
                         relative_path = "/" + banner_info.first.local_path.split("/")[-4..-1].join("/") unless banner_info.empty?
                         { filename:, relative_path:, alt_text: alttext }
                       end
    end

    # use either the indexed thumbnail or find the branding for the collection
    def thumbnail_file
      @thumbnail_file ||= collection_thumbnail(solr_document)
    end

    # Begin Featured Collections Methods
    def collection_featurable?
      user_can_feature_collection? && solr_document.public?
    end

    ##
    # OVERRIDE to handle search_only tenant's not having access to the collection type badge from
    # the document's home tenant.
    #
    # @return [String]
    #
    # @see https://github.com/notch8/palni-palci/issues/951
    # @see https://github.com/samvera/hyku/issues/1815
    def collection_type_badge
      return "" unless Site.account&.present?
      return "" if Site.account.search_only?

      super
    rescue ActiveRecord::RecordNotFound
      # This is a fail-safe if we deleted the underlying Hyrax::CollectionType but have not yet
      # cleaned up the SOLR records.
      ""
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
  end
end

Hyrax::CollectionPresenter.prepend(Hyrax::CollectionPresenterDecorator)
