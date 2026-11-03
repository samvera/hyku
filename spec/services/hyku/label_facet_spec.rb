# frozen_string_literal: true

RSpec.describe Hyku::LabelFacet do
  let(:config) { Blacklight::Configuration.new { |c| c.add_facet_field 'subject_label_sim' } }

  it "uses a field's label facet when the config has one" do
    expect(described_class.for(config, 'subject_sim')).to eq('subject_label_sim')
  end

  it 'keeps the field when the config has no label facet for it' do
    expect(described_class.for(config, 'resource_type_sim')).to eq('resource_type_sim')
  end

  it 'keeps a field with no suffix to label' do
    expect(described_class.for(config, 'subject')).to eq('subject')
  end
end
