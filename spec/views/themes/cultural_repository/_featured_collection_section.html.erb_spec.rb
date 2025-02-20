# frozen_string_literal: true

RSpec.describe "themes/cultural_repository/hyrax/homepage/_featured_collection_section.html.erb", type: :view do
  let(:list) { FeaturedCollectionList.new }
  let(:presenter) do
    Hyku::WorkShowPresenter.new(
      SolrDocument.new(
        id: '123',
        title_tesim: ['Featured Collection'],
        has_model_ssim: ['Collection']
      ),
      nil
    )
  end
  let(:featured_collection) { FeaturedCollection.new }
  let(:rendered_template) { render }

  before do
    assign(:featured_collection_list, list)
    allow(view).to receive(:can?).with(:update, FeaturedCollection).and_return(false)
    allow(view).to receive(:render_thumbnail_tag).with(presenter, any_args).and_return('thumbnail')
    allow(view).to receive(:main_app).and_return(main_app)
  end

  context "when there are no featured collections" do
    before { render }

    it "displays the 'no collections' message" do
      expect(rendered).to have_content(t('hyrax.homepage.featured_collections.no_collections'))
    end

    it "does not show the form" do
      expect(rendered).not_to have_selector('form')
    end
  end

  context "when user can update featured collections" do
    before do
      allow(view).to receive(:can?).with(:update, FeaturedCollection).and_return(true)
      allow(view).to receive(:can?).with(:destroy, FeaturedCollection).and_return(true)
      allow(list).to receive(:empty?).and_return(false)
      allow(list).to receive(:featured_collections).and_return([featured_collection])
      allow(featured_collection).to receive(:presenter).and_return(presenter)

      allow(view).to receive(:render_thumbnail_tag).with(
        presenter.solr_document,
        { alt: "Featured Collection Thumbnail" },
        { suppress_link: true }
      ).and_return('thumbnail')

      render
    end

    it "displays the form for reordering" do
      expect(rendered).to have_selector('form')
      expect(rendered).to have_selector('#ff')
      expect(rendered).to have_selector('#featured_works')
      expect(rendered).to have_selector('input[type="submit"][value="Save order"]')
    end
  end

  context "when user cannot update featured collections" do
    before do
      allow(list).to receive(:empty?).and_return(false)
      allow(list).to receive(:featured_collections).and_return([featured_collection])
      allow(featured_collection).to receive(:presenter).and_return(presenter)
      render
    end

    it "displays the collections in a grid" do
      expect(rendered).to have_selector('.container')
      expect(rendered).to have_selector('.row')
    end

    it "displays the link to browse all collections" do
      expect(rendered).to have_selector('.collection-highlights-list')
      expect(rendered).to have_link(t('hyrax.homepage.admin_sets.link'))
    end
  end
end
