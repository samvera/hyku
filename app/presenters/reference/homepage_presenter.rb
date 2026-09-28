# frozen_string_literal: true

module Reference
  class HomepagePresenter
    include ThemeHomepage

    COLUMN_ROWS = 5
    BROWSE_FIELDS = { 'subject_sim' => :subjects,
                      'creator_sim' => :creators,
                      'member_of_collections_ssim' => :collections,
                      'publisher_sim' => :publishers }.freeze

    def browse_columns
      @browse_columns ||= BROWSE_FIELDS.filter_map do |field, key|
        items = facet_items(field, "f.#{field}.facet.limit" => (COLUMN_ROWS + 1).to_s)
        next if items.empty?

        { field:, key:, items: items.first(COLUMN_ROWS), more: items.size > COLUMN_ROWS }
      end
    end
  end
end
