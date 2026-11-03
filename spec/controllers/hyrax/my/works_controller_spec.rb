# frozen_string_literal: true

RSpec.describe Hyrax::My::WorksController, type: :controller do
  describe "#configure_facets" do
    subject { controller.blacklight_config.sort_fields.keys }

    let(:expected_sort_fields) do
      [
        "date_uploaded_dtsi desc",
        "date_uploaded_dtsi asc",
        "date_modified_dtsi desc",
        "date_modified_dtsi asc",
        "system_create_dtsi desc",
        "system_create_dtsi asc",
        "depositor_ssi asc, title_ssi asc",
        "depositor_ssi desc, title_ssi desc",
        "creator_ssi asc, title_ssi asc",
        "creator_ssi desc, title_ssi desc"
      ]
    end

    it "configures the custom sort fields" do
      expect(subject).to match_array(expected_sort_fields)
    end

    [described_class, Hyrax::Dashboard::WorksController].each do |works_controller|
      it "lists the catalog's default number of collections on #{works_controller}" do
        search_builder = works_controller.blacklight_config.search_builder_class.new(works_controller.new)

        expect(search_builder.facet_limit_for('member_of_collections_ssim'))
          .to eq(::CatalogController.blacklight_config.default_facet_limit)
      end
    end
  end
end
