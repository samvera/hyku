# frozen_string_literal: true

# The shipped vocabularies each have a module-level service, and the deposit form asks
# a service for its options. Without select_active_options here the form falls back to
# select_all_options, so retiring a term in the dashboard changes nothing a depositor
# sees — only vocabularies with no service class honored the flag.
RSpec.describe Hyrax::AuthorityService, type: :model, clean: true do
  let(:vocabulary) { Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms') }

  let(:service) do
    Module.new do
      extend Hyrax::AuthorityService
      authority_name 'reading_rooms'
    end
  end

  before do
    vocabulary.local_authority_entries.create!(label: 'Special Collections', uri: 'special')
    vocabulary.local_authority_entries.create!(label: 'Closed Stacks', uri: 'closed', active: false)
    # Built once per service and memoized, so a subauthority resolved before these
    # rows existed would answer from an empty vocabulary.
    service.authority = Qa::Authorities::Local.subauthority_for('reading_rooms')
  end

  describe '#select_active_options' do
    it 'omits a retired term' do
      expect(service.select_active_options.map(&:first)).to eq ['Special Collections']
    end

    it 'still offers every term through select_all_options' do
      expect(service.select_all_options.map(&:first))
        .to contain_exactly('Special Collections', 'Closed Stacks')
    end
  end

  # A yaml vocabulary may omit `active` altogether. Hyrax treats such a term as
  # usable, so it has to survive the filter rather than be read as retired.
  describe 'a term with no active flag' do
    let(:authority) { instance_double(Qa::Authorities::LocalVocabulary) }

    before do
      allow(authority).to receive(:all).and_return(
        [{ 'id' => 'a', 'label' => 'Stated', 'active' => true }.with_indifferent_access,
         { 'id' => 'b', 'label' => 'Unstated' }.with_indifferent_access]
      )
      service.authority = authority
    end

    it 'is offered' do
      expect(service.select_active_options.map(&:first)).to contain_exactly('Stated', 'Unstated')
    end
  end

  # A tenant that has never been seeded has no rows, so the authority reads the yaml
  # file instead. Terms are looked up by symbol, as upstream's select_all_options
  # does, which holds only because qa returns indifferent hashes.
  describe 'a vocabulary still backed by its yaml file' do
    let(:unseeded) do
      Module.new do
        extend Hyrax::AuthorityService
        authority_name 'resource_types'
      end
    end

    it 'reads the terms the file supplies' do
      expect(unseeded.authority.all.first).to be_a ActiveSupport::HashWithIndifferentAccess
      expect(unseeded.select_active_options).to be_present
      expect(unseeded.select_active_options).to all(match([be_present, be_present]))
    end

    it 'offers the same terms as the unfiltered list' do
      expect(unseeded.select_active_options).to eq unseeded.select_all_options
    end
  end
end
