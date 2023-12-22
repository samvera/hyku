# frozen_string_literal: true

RSpec.describe AdvSearchBuilder do
  let(:scope) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:access) { :read }
  let(:builder) { described_class.new(scope).with_access(access) }

  it "can be instantiated" do
    expect(builder).to be_instance_of(described_class)
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    let(:expected_default_processor_chain) do
      # Yes there's a duplicate for add_access_controls_to_solr_params; but that does not appear to
      # be causing a problem like the duplication and order of the now removed additional
      # :add_advanced_parse_q_to_solr, :add_advanced_search_to_solr filters.  Those existed in their
      # current position and at the end of the array.
      #
      # When we had those duplicates, the :add_advanced_parse_q_to_solr obliterated the join logic
      # for files.
      #
      # Is the order immutable?  No.  But it does highlight that you must consider what the changes
      # might mean and double check that join logic on files.
      %i[
        default_solr_parameters
        add_search_field_default_parameters
        add_query_to_solr
        add_facet_fq_to_solr
        add_facetting_to_solr
        add_solr_fields_to_query
        add_paging_to_solr
        add_sorting_to_solr
        add_group_config_to_solr
        add_facet_paging_to_solr
        add_adv_search_clauses
        add_additional_filters
        add_range_limit_params
        add_access_controls_to_solr_params
        filter_models
        only_active_works
        add_advanced_parse_q_to_solr
        add_advanced_search_to_solr
        add_access_controls_to_solr_params
        show_works_or_works_that_contain_files
        show_only_active_records
        filter_collection_facet_for_access
        exclude_models
        highlight_search_params
        show_parents_only
        include_allinson_flex_fields
      ]
    end

    it { is_expected.to eq(expected_default_processor_chain) }
  end
end
