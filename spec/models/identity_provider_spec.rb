# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IdentityProvider, type: :model do
  subject do
    described_class.new(
      name: 'SAML Test',
      provider: 'saml'
    )
  end

  context 'attributes and validations' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without a name' do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it 'is not valid without a provider' do
      subject.provider = nil
      expect(subject).not_to be_valid
    end
  end
end
