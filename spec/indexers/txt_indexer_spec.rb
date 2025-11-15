# frozen_string_literal: true

RSpec.describe 'txt indexer' do
  let(:work) { valkyrie_create(:generic_work_resource) }
  let(:file_set) { valkyrie_create(:hyrax_file_set, :with_files, ios: [File.open(File.join(file_fixture_path, 'files', 'text_file.txt'))]) }

  before do
    fm = file_set.original_file
    fm.mime_type = 'text/plain' # since it doesn't go through characterization in a spec we have to set it manually
    Hyrax.persister.save(resource: fm)
    work.member_ids << file_set.id
    work.save
  end

  it 'indexes txt files onto the work' do
    indexer = "#{work.class}Indexer".constantize
    expect(indexer.included_modules).to include(HykuIndexing)
    expect(work.to_solr['all_text_tsimv']).to eq('Hello world!')
  end
end
