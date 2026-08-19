# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::Authorities::LocalVocabulary do
  subject(:authority) { Qa::Authorities::Local.subauthority_for('audience') }

  let(:yml_terms) { YAML.load_file(Rails.root.join('config', 'authorities', 'audience.yml'))['terms'] }

  describe '#locally_owned?' do
    it 'is true, because nothing external overwrites these terms' do
      expect(authority).to be_locally_owned
    end
  end

  it 'serves the tenant rows when the vocabulary is in the database' do
    Qa::LocalAuthority.find_by(name: 'audience')
                      .local_authority_entries
                      .create!(label: 'Registrar', uri: 'registrar')

    expect(authority.all.map { |term| term[:label] }).to include('Registrar')
  end

  it 'falls back to config/authorities when the tenant has no row' do
    Qa::LocalAuthority.where(name: 'audience').destroy_all

    expect(authority.all.map { |term| term[:label] }).to eq yml_terms.map { |term| term['term'] }
  end

  it 'reports a retired term as inactive' do
    entry = Qa::LocalAuthority.find_by(name: 'audience').local_authority_entries.first
    entry.update!(active: false)

    expect(authority.find(entry.uri)['active']).to be false
  end

  it 'returns an empty hash for an unknown term, as the file-based authority does' do
    expect(authority.find('no-such-term')).to eq({})
  end
end
