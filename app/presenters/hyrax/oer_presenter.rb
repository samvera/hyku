# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  class OerPresenter < Hyku::WorkShowPresenter
    delegate :alternative_title, :date, :table_of_contents, :additional_information,
             :rights_holder, :oer_size, :accessibility_feature, :accessibility_hazard,
             :accessibility_summary, :audience, :education_level, :learning_resource_type, 
             :discipline, :previous_version, to: :solr_document
    
    # @return [Array] list to display with Kaminari pagination
    # for use in _related_items.html.erb partial
    def list_of_previous_item_ids_to_display
      paginated_item_list(page_array: authorized_previous_item_ids)
    end

    private

      # gets list of ids for previous versions
      def authorized_previous_item_ids
        @item_list_ids ||= begin
          items = previous_version_ids
          items.delete_if { |m| !current_ability.can?(:read, m) } if Flipflop.hide_private_items?
          items
        end
      end

      #TODO: This isn't working yet
      # get list of ids from solr for the previous_versions
      # Arbitrarily maxed at 10 thousand; had to specify rows due to solr's default of 10
      def previous_version_ids
        @previous_version_ids ||= begin
          ActiveFedora::SolrService.query("proxy_in_ssi:#{id}", #what is proxy_in_ssi?
            rows: 10_000,
            fl:   "previous_version_ssim")
          .flat_map { |x| x.fetch("previous_version_ssim", []) }
        end
      end
  end
end
