# frozen_string_literal: true

RSpec.describe IiifSearchBuilder do
  let(:scope) { double(blacklight_config: CatalogController.blacklight_config, current_ability: Ability.new(nil)) }
  let(:solr_params) { described_class.new(scope).with(q: 'harbor').to_hash }

  it 'highlights the full text with the original highlighter, whose snippets place the UV hits' do
    expect(solr_params).to include(hl: true, 'hl.fl': 'all_text_tsimv')
    expect(solr_params.to_h.stringify_keys).not_to have_key('hl.method')
  end
end
