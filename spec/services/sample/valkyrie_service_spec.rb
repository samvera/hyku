# frozen_string_literal: true

RSpec.describe Sample::ValkyrieService do
  let(:service) { described_class.new(tenant_name, 1, requested_visibility) }
  let(:tenant_name) { 'sample-tenant' }
  let(:requested_visibility) { nil }

  describe '#create_sample_data' do
    around do |example|
      original_env = ENV['HYRAX_VALKYRIE']
      original_use_valkyrie = Hyrax.config.use_valkyrie?
      example.run
    ensure
      Hyrax.config.use_valkyrie = original_use_valkyrie
      if original_env.nil?
        ENV.delete('HYRAX_VALKYRIE')
      else
        ENV['HYRAX_VALKYRIE'] = original_env
      end
    end

    before do
      allow(service).to receive(:validate_and_switch_tenant)
      allow(service).to receive(:load_sample_data)
      allow(service).to receive(:setup_dependencies)
      allow(service).to receive(:setup_job_configuration)
      allow(service).to receive(:restore_job_configuration)
      allow(service).to receive(:find_or_create_admin_set)
      allow(service).to receive(:create_collections).and_return([])
      allow(service).to receive(:create_works_of_type).and_return([])
      allow(service).to receive(:index_all_works)
    end

    # Regression: the completion summary required an OER argument that this
    # service never passes, so the task crashed after creating and indexing
    # every record.
    it 'prints the completion summary without raising' do
      expect { service.create_sample_data }.not_to raise_error
    end

    it 'creates every work type the tenant offers, not a hardcoded pair' do
      allow(service).to receive(:available_work_type_names).and_return(%w[GenericWork Image Etd])

      service.create_sample_data

      expect(service).to have_received(:create_works_of_type).with('GenericWork', 1, [])
      expect(service).to have_received(:create_works_of_type).with('Image', 1, [])
      expect(service).to have_received(:create_works_of_type).with('Etd', 1, [])
    end

    context 'with explicit per-type counts' do
      let(:service) { described_class.new(tenant_name, 1, nil, work_types: { 'image' => 3 }) }

      it 'uses the requested counts and skips the other types' do
        allow(service).to receive(:available_work_type_names).and_return(%w[GenericWork Image])

        service.create_sample_data

        expect(service).to have_received(:create_works_of_type).with('Image', 3, [])
        expect(service).not_to have_received(:create_works_of_type).with('GenericWork', anything, anything)
      end
    end

    context 'with a work type the tenant does not offer' do
      let(:service) { described_class.new(tenant_name, 1, nil, work_types: { 'nope' => 1 }) }

      it 'raises rather than silently seeding nothing' do
        allow(service).to receive(:available_work_type_names).and_return(%w[GenericWork Image])

        expect { service.create_sample_data }.to raise_error(ArgumentError, /Unknown work type 'nope'/)
      end
    end
  end

  describe 'seeded record visibility' do
    let(:user) { create(:user) }
    let(:admin_set) { FactoryBot.valkyrie_create(:hyku_admin_set) }
    let(:collection_type) { Hyrax::CollectionType.find_or_create_default_collection_type }
    let(:sample_data) do
      {
        titles: ['A Sample Title'],
        descriptions: ['A sample description.'],
        creators: [['Sample Creator']],
        subjects: [['Sample Subject']]
      }
    end

    before do
      allow(Hyrax.publisher).to receive(:publish)
      allow(Hyrax.index_adapter).to receive(:save)
      allow(service).to receive(:sample_data).and_return(sample_data)
      service.user = user
      service.admin_set = admin_set
    end

    context 'when no visibility is requested' do
      it 'leaves seeded works restricted' do
        work = service.send(:build_work, GenericWorkResource, 1, 'GenericWorkResource')
        reloaded = Hyrax.query_service.find_by(id: work.id)
        expect(reloaded.visibility).to eq 'restricted'
      end
    end

    context 'when initialized with open visibility' do
      let(:requested_visibility) { 'open' }

      it 'creates works that anonymous users can read' do
        work = service.send(:build_work, GenericWorkResource, 1, 'GenericWorkResource')
        reloaded = Hyrax.query_service.find_by(id: work.id)
        expect(reloaded.visibility).to eq 'open'
      end

      it 'persists a public read group on the work ACL' do
        work = service.send(:build_work, GenericWorkResource, 1, 'GenericWorkResource')
        reloaded = Hyrax.query_service.find_by(id: work.id)
        expect(reloaded.permission_manager.read_groups.to_a).to include 'public'
      end

      it 'creates collections that anonymous users can read' do
        collection = service.send(:build_collection, 1, collection_type)
        reloaded = Hyrax.query_service.find_by(id: collection.id)
        expect(reloaded.visibility).to eq 'open'
      end
    end
  end
end
