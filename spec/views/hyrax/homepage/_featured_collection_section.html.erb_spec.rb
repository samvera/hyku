# frozen_string_literal: true

RSpec.describe "hyrax/homepage/_featured_collection_section.html.erb", type: :view, singletenant: true do
  subject { rendered }

  let(:list) { FeaturedCollectionList.new }

  before { assign(:featured_collection_list, list) }

  context "without featured collections" do
    before { render }
    it do
      is_expected.to have_content 'No collections have been featured'
      is_expected.not_to have_selector('form')
    end
  end

  context "with featured collections" do
    let(:doc) do
      SolrDocument.new(id: '12345678',
                       title_tesim: ['Doc title'],
                       has_model_ssim: ['Collection'])
    end
    let(:presenter) { Hyku::WorkShowPresenter.new(doc, nil) }
    let(:featured_collection) { FeaturedCollection.new }

    before do
      allow(view).to receive(:can?).with(:update, FeaturedCollection).and_return(false)
      allow(view).to receive(:render_thumbnail_tag).with(presenter, any_args).and_return('thumbnail')
      allow(list).to receive(:empty?).and_return(false)
      allow(list).to receive(:featured_collections).and_return([featured_collection])
      allow(featured_collection).to receive(:presenter).and_return(presenter)
      render
    end

    it do
      is_expected.not_to have_content 'No collections have been featured'
      is_expected.not_to have_selector('#no-collections')
      is_expected.to have_selector('form')
    end
  end
end
