# frozen_string_literal: true

RSpec.describe BlacklightAdvancedSearch::RenderConstraintsOverrideDecorator do
  let(:helper_class) do
    Class.new do
      include BlacklightAdvancedSearch::RenderConstraintsOverride

      def blacklight_config
        CatalogController.blacklight_config
      end
    end
  end
  let(:helper) { helper_class.new }
  let(:params) do
    ActionController::Parameters.new(
      op: 'AND', search_field: 'advanced',
      f_inclusive: { 'language_sim' => ['English'], 'resource_type_sim' => ['Image'] }
    )
  end
  let(:search_state) { Blacklight::SearchState.new(params, CatalogController.blacklight_config) }

  describe '#remove_advanced_filter_group' do
    it 'drops only the removed limit' do
      result = helper.remove_advanced_filter_group('language_sim', search_state)

      expect(result[:f_inclusive]).to eq('resource_type_sim' => ['Image'])
      expect(result[:op]).to eq('AND')
    end

    it 'drops f_inclusive once its last limit is removed' do
      one_limit = Blacklight::SearchState.new(
        ActionController::Parameters.new(op: 'AND', f_inclusive: { 'language_sim' => ['English'] }),
        CatalogController.blacklight_config
      )

      expect(helper.remove_advanced_filter_group('language_sim', one_limit)).not_to have_key(:f_inclusive)
    end

    # SearchState#to_h returns a plain Hash with string keys in production.
    it 'handles string-keyed params' do
      allow_any_instance_of(Blacklight::SearchState).to receive(:to_h).and_return(
        'op' => 'AND', 'f_inclusive' => { 'language_sim' => ['English'], 'resource_type_sim' => ['Image'] }
      )

      expect { helper.remove_advanced_filter_group('language_sim', search_state) }.not_to raise_error
      expect(helper.remove_advanced_filter_group('language_sim', search_state)[:f_inclusive])
        .to eq('resource_type_sim' => ['Image'])
    end

    it 'returns the params unchanged when there are no limits' do
      plain = Blacklight::SearchState.new(ActionController::Parameters.new(q: 'cats'), CatalogController.blacklight_config)

      expect(helper.remove_advanced_filter_group('language_sim', plain)).to eq(plain)
    end
  end
end
