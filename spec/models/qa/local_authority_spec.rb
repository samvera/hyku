require 'spec_helper'

RSpec.describe Qa::LocalAuthority, type: :model do
  it "can persist data" do
    expect { described_class.create!(name: 'Language') }
      .to change(described_class, :count).by(1)
  end
end
