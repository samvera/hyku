# frozen_string_literal: true

RSpec.describe Hyku do
  it 'has a version' do
    expect(described_class).to have_constant(:VERSION)
  end
end
