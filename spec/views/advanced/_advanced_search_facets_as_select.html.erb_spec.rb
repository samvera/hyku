# frozen_string_literal: true

RSpec.describe 'advanced/_advanced_search_facets_as_select.html.erb', type: :view do
  shared_examples_for 'lists the facets the catalog sidebar shows' do |partial|
    let(:config) do
      Blacklight::Configuration.new.tap do |blacklight|
        blacklight.add_facet_field 'subject_sim', label: 'Subject', if: false
        blacklight.add_facet_field 'subject_label_sim', label: 'Subject'
        blacklight.add_facet_field 'date_range_isim', label: 'Date Range', include_in_advanced_search: false
        blacklight.add_facet_field 'has_model_ssim', label: 'Work Type', helper_method: :spaced_model_name
      end
    end
    let(:items) { ->(*values) { values.map { |value| Blacklight::Solr::Response::Facets::FacetItem.new(value:, hits: 1) } } }
    let(:facets) do
      [Blacklight::Solr::Response::Facets::FacetField.new('subject_sim', items.call('summertime')),
       Blacklight::Solr::Response::Facets::FacetField.new('subject_label_sim', items.call('Pink Pajamas')),
       Blacklight::Solr::Response::Facets::FacetField.new('date_range_isim', items.call('1990')),
       Blacklight::Solr::Response::Facets::FacetField.new('has_model_ssim', items.call('GenericWork'))]
    end
    let(:page) { Capybara.string(rendered) }

    before do
      blacklight = config
      available = facets
      view.define_singleton_method(:blacklight_config) { blacklight }
      view.define_singleton_method(:blacklight_configuration_context) { Blacklight::Configuration::Context.new(self) }
      view.define_singleton_method(:search_state) { Blacklight::SearchState.new({}, blacklight, controller) }
      view.define_singleton_method(:spaced_model_name, &:titleize)
      without_partial_double_verification do
        allow(view).to receive_messages(facet_field_names: available.map(&:name), facet_value_checked?: false)
        allow(view).to receive(:facets_from_request) { |names| available.select { |facet| names.include?(facet.name) } }
      end
      render partial:
    end

    it 'lists a facet the catalog sidebar shows' do
      expect(page).to have_css("select[name='f_inclusive[subject_label_sim][]'] option[value='Pink Pajamas']")
    end

    it 'leaves out a facet the catalog sidebar hides, such as the stored values behind a label facet' do
      expect(page).to have_no_css("select[name='f_inclusive[subject_sim][]']")
    end

    it 'leaves out a facet configured out of advanced search' do
      expect(page).to have_no_css("select[name='f_inclusive[date_range_isim][]']")
    end

    it "shows each option through the facet's display helper" do
      expect(page).to have_css("select[name='f_inclusive[has_model_ssim][]'] option[value='GenericWork']", text: 'Generic Work')
    end
  end

  it_behaves_like 'lists the facets the catalog sidebar shows', 'advanced/advanced_search_facets_as_select'

  context 'with the digital collection theme' do
    it_behaves_like 'lists the facets the catalog sidebar shows', 'themes/digital_collection/advanced/advanced_search_facets_as_select'
  end
end
