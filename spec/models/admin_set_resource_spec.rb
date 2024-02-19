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

  its(:internal_resource) { is_expected.to eq('AdminSet') }

  context 'class configuration' do
    subject { described_class }
    its(:to_rdf_representation) { is_expected.to eq('AdminSet') }
  end
end
