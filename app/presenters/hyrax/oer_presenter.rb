# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  class OerPresenter < Hyku::WorkShowPresenter
    delegate :alternative_title, :date, :table_of_contents, :additional_information,
             :rights_holder, :oer_size, :accessibility_feature, :accessibility_hazard,
             :accessibility_summary, :audience, :education_level, :learning_resource_type,
             :discipline, to: :solr_document

    # @return [Array] list to display with Kaminari pagination
    # for use in _related_items.html.erb partial
    def previous_versions
      paginated_item_list(page_array: authorized_previous_versions)
    end

    def newer_versions
      paginated_item_list(page_array: authorized_newer_versions)
    end

    def alternate_versions
      paginated_item_list(page_array: authorized_alternate_versions)
    end

    private

      # gets list of ids for previous versions
      def authorized_previous_versions
        @pv_item_list_ids ||= begin
          items = previous_version
          items.delete_if { |m| !current_ability.can?(:read, m) } if Flipflop.hide_private_items?
          items
        end
      end

      def authorized_newer_versions
        @nv_item_list_ids ||= begin
          items = newer_version
          items.delete_if { |m| !current_ability.can?(:read, m) } if Flipflop.hide_private_items?
          items
        end
      end

      def authorized_alternate_versions
        @av_item_list_ids ||= begin
          items = alternate_version
          items.delete_if { |m| !current_ability.can?(:read, m) } if Flipflop.hide_private_items?
          items
        end
      end

      # get list of ids from solr for the related items
      # Arbitrarily maxed at 10 thousand; had to specify rows due to solr's default of 10
      def previous_version
        @previous_version_id ||= begin
          ActiveFedora::SolrService.query("id:#{id}",
            rows: 10_000,
            fl:   "previous_version_id_tesim")
          .flat_map { |x| x.fetch("previous_version_id_tesim", []) }
        end
      end

      # get list of ids from solr for the related items
      # Arbitrarily maxed at 10 thousand; had to specify rows due to solr's default of 10
      def newer_version
        @newer_version_id ||= begin
          ActiveFedora::SolrService.query("id:#{id}",
            rows: 10_000,
            fl:   "newer_version_id_tesim")
          .flat_map { |x| x.fetch("newer_version_id_tesim", []) }
        end
      end

      # get list of ids from solr for the related items
      # Arbitrarily maxed at 10 thousand; had to specify rows due to solr's default of 10
      def alternate_version
        @alternate_version_id ||= begin
          ActiveFedora::SolrService.query("id:#{id}",
            rows: 10_000,
            fl:   "alternate_version_id_tesim")
          .flat_map { |x| x.fetch("alternate_version_id_tesim", []) }
        end
      end
  end
end
