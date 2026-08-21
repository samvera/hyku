# frozen_string_literal: true

RSpec.describe Hyrax::AttributesHelperDecorator, type: :helper do
  describe '#conform_options' do
    it 'restores the license renderer the flexible path loses' do
      options = helper.conform_options(:license, {})
      expect(options[:render_as]).to eq(:license)
    end

    it 'restores the rights statement renderer' do
      options = helper.conform_options(:rights_statement, {})
      expect(options[:render_as]).to eq(:rights_statement)
    end

    it 'overrides a profile-specified external_link for license' do
      # Tenants seeded before the profile fix store render_as: external_link in
      # their flexible schema; the semantic renderer must win anyway, since a
      # license label still links to the URI and a bare URI is strictly worse.
      options = helper.conform_options(:license, { render_as: 'external_link' })
      expect(options[:render_as]).to eq(:license)
    end

    it 'leaves other fields without a semantic renderer' do
      options = helper.conform_options(:description, {})
      expect(options[:render_as]).to be_nil
    end
  end
end
