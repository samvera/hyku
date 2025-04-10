# frozen_string_literal: true

RSpec.describe Hyrax::FileSet do
  describe '.model_name' do
    subject { described_class.model_name }
  end

  subject { described_class.new }
  its(:internal_resource) { is_expected.to eq('FileSet') }

  context 'class configuration' do
    subject { described_class }
    its(:to_rdf_representation) { is_expected.to eq('FileSet') }
  end

  context 'lazy migration' do
    let(:logger) { instance_double(Logger) }

    before do
      allow_any_instance_of(MigrateFilesToValkyrieJob).to receive(:logger).and_return(logger)
    end

    # given an existing AF FileSet
    let(:af_file_set) do
      fs = FileSet.create(creator: ['test'], title: ['file set test'], label: 'sample.csv')
      path_to_file = 'spec/fixtures/csv/sample.csv'
      file = File.open(path_to_file, 'rb')
      Hydra::Works::AddFileToFileSet.call(fs, file, :original_file)
      fs
    end
    let(:file_set_resource) { Hyrax.query_service.find_by(id: af_file_set.id) }
    let(:paths) { ['spec/fixtures/derivatives/00-xml.xml', 'spec/fixtures/derivatives/b6-thumbnail.jpeg'] }
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:derivatives_disk) }

    before do
      # set up some derivatives
      allow(Hyrax::DerivativePath).to receive(:derivatives_for_reference).and_return(paths)
      allow(Hyrax::ValkyriePersistDerivatives).to receive(:fileset_for_directives).and_return(file_set_resource)
      allow(Hyrax.publisher).to receive(:publish)
    end

    # Because we're running a job, we need to specify a tenant
    it "converts an AF FileSet to a Valkyrie::FileSet", :singletenant do
      ## Preamble to test a "Created in ActiveFedora FileSet"
      expect { Hyrax.query_service.services.first.find_by(id: af_file_set.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      # We are lazily migrating a FileSet to a Hyrax::FileSet
      # thus it should comeback as a Hyrax::FileSet
      expect(Hyrax.query_service.services.last.find_by(id: af_file_set.id)).to be_a(Hyrax::FileSet)
      # Expect the goddess combo works as expected
      expect(file_set_resource).to be_a(Hyrax::FileSet)

      expect { Hyrax.query_service.services.first.find_by(id: af_file_set.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      # We should be able to find this "thing" in the ActiveFedora storage
      expect(Hyrax.query_service.services.last.find_by(id: af_file_set.id)).to be_present
      # Expect the goddess combo works as expected
      expect(Hyrax.query_service.find_by(id: af_file_set.id)).to be_present

      # The file is in Fedora!
      expect(file_set_resource.original_file.file_identifier.id).to start_with("fedora://")

      ## Do the "migration" task: saving the resource triggers the file migrations.
      # if we don't process the queue the statements after this will fail.
      perform_enqueued_jobs do
        Hyrax.persister.save(resource: file_set_resource)
      end

      ## Verify FileSet migration
      # We found the file_set in Postgresql
      converted_file_set = Hyrax.query_service.services.first.find_by(id: af_file_set.id)
      expect(converted_file_set).to be_a(Hyrax::FileSet)

      ## Verify File migration
      af_file_id = af_file_set.original_file.id
      # It's been converted to Valkyrie if we have a Hyrax::FileMetadata object.
      expect(Hyrax.custom_queries.find_file_metadata_by(id: af_file_id)).to be_a(Hyrax::FileMetadata)

      file_identifier_id = converted_file_set.original_file.file_identifier.id
      # Verify that the original file is now on disk (e.g. where we write files in
      # the test environment)
      expect(file_identifier_id).to start_with("disk://#{Rails.root}")

      # Verify that the file actually exists there!
      expect(File.exist?(file_identifier_id.sub("disk://", ""))).to be_truthy

      # Verify that it's still in ActiveFedora
      expect(af_file_set.original_file).to be_a(Hydra::PCDM::File)
      expect(Hydra::PCDM::File.find(af_file_set.original_file.uri.to_s).content).to be_present

      # Verify that we have migrated derivatives & original file... The file_set should have 3 FileMetadata objects.
      expect(Hyrax.custom_queries.find_many_file_metadata_by_ids(ids: converted_file_set.file_ids).count).to eq(3)
    end
  end
end
