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

  # given an existing AF FileSet
  let(:af_file_set) do
    fs = FileSet.create(creator: ['test'], title: ['file set test'])
    path_to_file = 'spec/fixtures/csv/sample.csv'
    file = File.open(path_to_file, 'rb')
    Hydra::Works::AddFileToFileSet.call(fs, file, :original_file)
    fs
  end

  # Because we're running a job, we need to specify a tenant
  it "converts an AF FileSet to a Valkyrie::FileSet", :singletenant do
    ## Preamble to test a "Created in ActiveFedora FileSet"
    expect { Hyrax.query_service.services.first.find_by(id: af_file_set.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
    # We are lazyily migrating a FileSet to a Hyrax::FileSet
    # thus it should comeback as a Hyrax::FileSet
    expect(Hyrax.query_service.services.last.find_by(id: af_file_set.id)).to be_a(Hyrax::FileSet)
    # Expect the goddess combo works as expected
    file_set_resource = Hyrax.query_service.find_by(id: af_file_set.id)
    expect(file_set_resource).to be_a(Hyrax::FileSet)

    af_file_id = af_file_set.original_file.id
    expect { Hyrax.query_service.services.first.find_by(id: af_file_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
    # We should be able to find this "thing" in the ActiveFedora storage
    expect(Hyrax.query_service.services.last.find_by(id: af_file_id)).to be_present
    # Expect the goddess combo works as expected
    expect(Hyrax.query_service.find_by(id: af_file_id)).to be_present

    # The file is in Fedora!
    expect(file_set_resource.original_file.file_identifier.id).to start_with("fedora://")

    ## Do the "migration" task, it will conditionally enqueue; if we don't
    ## process the queue the statements after this will fail.
    perform_enqueued_jobs do
      Hyrax.persister.save(resource: file_set_resource)
    end

    # We found it in Postgresql
    converted_file_set = Hyrax.query_service.services.first.find_by(id: af_file_set.id)
    expect(converted_file_set).to be_a(Hyrax::FileSet)

    # It's been converted to Postgresql
    expect(Hyrax.query_service.services.first.find_by(id: af_file_id)).to be_a(Hyrax::FileMetadata)
    # It's still there in ActiveFedora
    expect(Hyrax.query_service.services.last.find_by(id: af_file_id)).to be_present
    # Expect the goddess combo works as expected
    expect(Hyrax.query_service.find_by(id: af_file_id)).to be_a(Hyrax::FileMetadata)

    file_identifier_id = converted_file_set.original_file.file_identifier.id
    # Verify that the original file is now on disk (e.g. where we write files in
    # the test environment)
    expect(file_identifier_id).to start_with("disk://#{Rails.root}")

    # Verify that the file actually exists there!
    expect(File.exist?(file_identifier_id.sub("disk://", ""))).to be_truthy
  end
end
