# frozen_string_literal: true

RSpec.describe 'themes/digital_collection/hyrax/homepage/_featured_fields.html.erb', type: :view do
  let(:document) do
    SolrDocument.new('id' => 'w1', 'has_model_ssim' => ['GenericWork'], 'title_tesim' => ['Harbor at dusk'],
                     'resource_type_tesim' => ['notoer'], 'resource_type_label_tesim' => ['NOT Oer'])
  end
  let(:featured) { double('featured', solr_document: document) }

  before do
    controller.prepend_view_path(Rails.root.join('app', 'views', 'themes', 'digital_collection'))
    without_partial_double_verification do
      allow(view).to receive_messages(generate_work_url: '/concern/generic_works/w1', block_valkyrie_redirect?: false,
                                      dc_creator_names: [], dc_summary: [], render_thumbnail_tag: '')
    end
    render partial: 'themes/digital_collection/hyrax/homepage/featured_fields', locals: { featured: }
  end

  it "badges a featured work with its resource type's label" do
    expect(Capybara.string(rendered)).to have_css('span.dc-badge', text: 'NOT Oer')
  end
end
