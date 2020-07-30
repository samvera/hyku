# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qa::LocalAuthorityEntry, type: :model do
  it "belongs to a local authority" do
    expect(described_class.reflections['local_authority'].macro).to eq :belongs_to
  end
end
