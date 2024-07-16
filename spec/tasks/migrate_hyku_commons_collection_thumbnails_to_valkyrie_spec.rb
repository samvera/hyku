# frozen_string_literal: true

RSpec.describe 'migrate_hyku_commons_collection_thumbnails_to_valkyrie' do
  let!(:account) { FactoryBot.create(:account) }
  let(:collection) { FactoryBot.create(:collection, title: ['Hyku Commons Collection']) }
  let(:thumbnail_path) { File.join('/', 'uploads', 'uploaded_collection_thumbnails', collection.id, "#{collection.id}_card.jpg") }
  let(:new_thumbnail_path) { Rails.root.join('public', 'branding', collection.id.to_s, 'thumbnail', "#{collection.id}_card.jpg").to_s }
  let(:old_thumbnail_path) { Rails.root.join(File.join('public', thumbnail_path)) }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    FileUtils.mkdir_p(File.dirname(old_thumbnail_path))
    FileUtils.touch(old_thumbnail_path)
    allow(Apartment::Tenant).to receive(:switch!).with(account.tenant) { |&block| block&.call }
    allow(collection).to receive(:to_solr).and_return({ 'id' => collection.id, 'thumbnail_path_ss' => thumbnail_path })
    allow(Collection).to receive(:find_each).and_yield(collection)
  end

  after do
    FileUtils.rm_rf(File.dirname(thumbnail_path))
    Collection.destroy_all
  end

  it 'migrates the old thumbnail to the branding directory' do
    expect(File.exist?(old_thumbnail_path)).to eq true
    expect(File.exist?(new_thumbnail_path)).to eq false
    run_task('hyku:migrate_hyku_commons_collection_thumbnails_to_valkyrie')
    expect(File.exist?(new_thumbnail_path)).to eq true
  end

  it 'creates a CollectionBrandingInfo object for the new thumbnail path' do
    expect(CollectionBrandingInfo.where(collection_id: collection.id, role: 'thumbnail').count).to eq 0
    run_task('hyku:migrate_hyku_commons_collection_thumbnails_to_valkyrie')
    expect(CollectionBrandingInfo.where(collection_id: collection.id, role: 'thumbnail').count).to eq 1
  end

  it 'indexes the new thumbnail path onto the collection resource' do
    original_thumbnail_path_ss = collection.to_solr['thumbnail_path_ss']
    expect(original_thumbnail_path_ss).to eq old_thumbnail_path.to_s.gsub(Rails.public_path.to_s, '')
    run_task('hyku:migrate_hyku_commons_collection_thumbnails_to_valkyrie')
    collection_resource = Hyrax.query_service.find_by(id: collection.id)
    expect(collection_resource.to_solr['thumbnail_path_ss']).to eq new_thumbnail_path.to_s.gsub(Rails.public_path.to_s, '')
  end
end
