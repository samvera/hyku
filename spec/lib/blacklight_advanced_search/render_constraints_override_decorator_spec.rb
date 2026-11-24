# frozen_string_literal: true

RSpec.describe BlacklightAdvancedSearch::RenderConstraintsOverrideDecorator do
  let(:helper) { Class.new { include BlacklightAdvancedSearch::RenderConstraintsOverride }.new }
  let(:blacklight_filters) do
    Module.new do
      def render_constraints_filters(_params)
        'blacklight filters'.html_safe
      end
    end
  end
  let(:params) { { op: 'AND', f_inclusive: { 'language_sim' => ['English'] } } }

  before do
    allow(Blacklight::RenderConstraintsHelperBehavior).to receive(:instance_method).and_call_original
    allow(Blacklight::RenderConstraintsHelperBehavior).to receive(:instance_method)
      .with(:render_constraints_filters).and_return(blacklight_filters.instance_method(:render_constraints_filters))
  end

  it 'is prepended to the gem override' do
    expect(BlacklightAdvancedSearch::RenderConstraintsOverride.ancestors.first).to eq(described_class)
  end

  it "renders the filters with Blacklight's implementation" do
    expect(helper.render_constraints_filters(params)).to eq('blacklight filters')
  end

  it "doesn't build the gem's duplicate constraint and its remove link" do
    allow(helper).to receive(:remove_advanced_filter_group)

    helper.render_constraints_filters(params)

    expect(helper).not_to have_received(:remove_advanced_filter_group)
  end
end
