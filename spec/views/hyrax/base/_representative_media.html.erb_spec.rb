RSpec.describe 'hyrax/base/_representative_media.html.erb' do
  let(:solr_doc) { double(representative_id: file_set.id, hydra_model: GenericWork) }
  let(:pres) { Hyrax::WorkShowPresenter.new(solr_doc, nil) }
  let(:file_set) { FileSet.create! { |fs| fs.apply_depositor_metadata('atz') } }
  let(:file_presenter) { double('file presenter', id: file_set.id, image?: true) }

  before do
    allow(pres).to receive_messages(representative_presenter: file_presenter)
    Hydra::Works::AddFileToFileSet.call(file_set,
                                        File.open(fixture_path + '/images/world.png'),
                                        :original_file)
    render 'hyrax/base/representative_media', presenter: pres
  end

  it 'has a universal viewer' do
    expect(rendered).to have_selector 'div.viewer'
  end
end
