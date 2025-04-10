# frozen_string_literal: true

RSpec.describe Hyrax::Transactions::WorkCreateDecorator, type: :decorator do
  subject(:transaction) { Hyrax::Transactions::WorkCreate.new }

  it 'uses the overridden DEFAULT_STEPS' do
    expect(described_class::DEFAULT_STEPS).to include 'change_set.add_custom_relations'
    expect(subject.steps).to eq described_class::DEFAULT_STEPS
  end
end
