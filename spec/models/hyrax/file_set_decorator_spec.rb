# frozen_string_literal: true

RSpec.describe Hyrax::FileSet do
  # given an existing AF FileSet
  let(:af_file_set) do
    fs = FileSet.create(creator: ['test'], title: ['file set test'])
    path_to_file = 'spec/fixtures/csv/sample.csv'
    file = File.open(path_to_file, 'rb')
    Hydra::Works::AddFileToFileSet.call(fs, file, :original_file)
    fs
  end

  it "converts an AF FileSet to a Valkyrie::FileSet" do
    expect { Hyrax.query_service.services.first.find_by(id: af_file_set.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
    # We are lazyily migrating a FileSet to a Hyrax::FileSet
    # thus it should comeback as a Hyrax::FileSet
    expect(Hyrax.query_service.services.last.find_by(id: af_file_set.id)).to be_a(Hyrax::FileSet)
    # Expect the goddess combo works as expected
    expect(Hyrax.query_service.find_by(id: af_file_set.id)).to be_a(Hyrax::FileSet)
  end
end
