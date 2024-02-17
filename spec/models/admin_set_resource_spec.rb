# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdminSetResource do
  subject(:admin_set) { described_class.new }

  it_behaves_like 'a Hyrax::AdministrativeSet'

  context 'with Hyrax::Permissions::Readable' do
    it { is_expected.to respond_to :public? }
    it { is_expected.to respond_to :private? }
    it { is_expected.to respond_to :registered? }
  end
end
