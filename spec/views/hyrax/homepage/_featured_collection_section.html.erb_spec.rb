# frozen_string_literal: true

RSpec.describe "hyrax/homepage/_featured_collection_section.html.erb", type: :view, singletenant: true do
  # Define helper methods at the example group level
  helper do
    def home_page_theme
      current_account.sites&.first&.home_theme || 'default_home'
    end

    def show_page_theme
      current_account.sites&.first&.show_theme || 'default_show'
    end

    def search_results_theme
      current_account.sites&.first&.search_theme || 'list_view'
    end
  end

  subject { rendered }

  let(:list) { FeaturedCollectionList.new }
  let(:doc) do
    SolrDocument.new(id: '12345678',
                     title_tesim: ['Doc title'],
                     has_model_ssim: ['Collection'])
  end
  let(:ability) { double }
  let(:presenter) { Hyku::WorkShowPresenter.new(doc, ability) }
  let(:featured_collection) { FeaturedCollection.new }
  let(:site) { Site.new(home_theme: 'cultural_repository') }
  let(:account) { create(:account) }

  before do
    assign(:featured_collection_list, list)
    allow(view).to receive(:render_thumbnail_tag).with(any_args).and_return('thumbnail')
    allow(view).to receive(:markdown).with(any_args).and_return('Doc title')
    allow(featured_collection).to receive(:presenter).and_return(presenter)
    allow(presenter).to receive(:solr_document).and_return(doc)
    allow(presenter).to receive(:title).and_return(['Doc title'])
    allow(presenter).to receive(:to_s).and_return('Doc title')

    # Add theme helper methods
    allow(view).to receive(:current_account).and_return(account)
    allow(account).to receive(:sites).and_return([site])
  end

  context "without featured collections" do
    before { render }
    it do
      is_expected.to have_content 'No collections have been featured'
      is_expected.not_to have_selector('form')
    end
  end

  context "with featured collections" do
    before do
      allow(view).to receive(:can?).with(:update, FeaturedCollection).and_return(false)
      allow(view).to receive(:can?).with(:destroy, FeaturedCollection).and_return(false)
      allow(list).to receive(:empty?).and_return(false)
      allow(list).to receive(:featured_collections).and_return([featured_collection])
    end

    context "in default theme" do
      before do
        allow(site).to receive(:home_theme).and_return('default_home')
        render
      end

      it "renders collections in a table" do
        is_expected.not_to have_content 'No collections have been featured'
        is_expected.not_to have_selector('#no-collections')
        is_expected.to have_selector('table.table.table-striped.collection-highlights')
      end
    end

    context "in cultural repository theme" do
      before do
        allow(site).to receive(:home_theme).and_return('cultural_repository')
        render
      end

      it "renders collections in a row layout" do
        is_expected.not_to have_content 'No collections have been featured'
        is_expected.not_to have_selector('#no-collections')
        is_expected.not_to have_selector('table.table')
        is_expected.to have_selector('div.row')
      end
    end

    context "in institutional repository theme" do
      before do
        allow(site).to receive(:home_theme).and_return('institutional_repository')
        render
      end

      it "renders collections in a row layout" do
        is_expected.not_to have_content 'No collections have been featured'
        is_expected.not_to have_selector('#no-collections')
        is_expected.not_to have_selector('table.table')
        is_expected.to have_selector('div.row')
      end
    end

    context "in neutral repository theme" do
      before do
        allow(site).to receive(:home_theme).and_return('neutral_repository')
        render
      end

      it "renders collections in a row layout" do
        is_expected.not_to have_content 'No collections have been featured'
        is_expected.not_to have_selector('#no-collections')
        is_expected.not_to have_selector('table.table')
        is_expected.to have_selector('div.row')
      end
    end
  end

  context "with featured collections and admin permissions" do
    before do
      allow(view).to receive(:can?).with(:update, FeaturedCollection).and_return(true)
      allow(view).to receive(:can?).with(:destroy, FeaturedCollection).and_return(true)
      allow(list).to receive(:empty?).and_return(false)
      allow(list).to receive(:featured_collections).and_return([featured_collection])
      render
    end

    it "renders sortable collections" do
      is_expected.to have_selector('div.dd')
      is_expected.to have_selector('div#ff')
      is_expected.to have_selector('ol#featured_works')
    end
  end
end
