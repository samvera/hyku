# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::PcdmCollection do
  subject(:collection) { described_class.new }

  it_behaves_like 'a Hyrax::PcdmCollection'

  context 'with Hyrax::Permissions::Readable' do
    subject { described_class.new }
    it { is_expected.to respond_to :public? }
    it { is_expected.to respond_to :private? }
    it { is_expected.to respond_to :restricted? }
  end
end
