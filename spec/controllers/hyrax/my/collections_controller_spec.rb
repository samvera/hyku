# frozen_string_literal: true

RSpec.describe Hyrax::My::CollectionsController, type: :controller do
  describe "#configure_facets" do
    subject { controller.blacklight_config.sort_fields.keys }

    let(:expected_sort_fields) do
      [
        "system_modified_dtsi desc",
        "system_modified_dtsi asc",
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
  end
end
