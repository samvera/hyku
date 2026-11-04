# frozen_string_literal: true

RSpec.describe Hyrax::PresenterRenderer, type: :view do
  let(:document) do
    SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['CollectionResource'],
                     'based_near_tesim' => ['http://sws.geonames.org/4254679/'],
                     'based_near_label_tesim' => ['Bloomington, Indiana, United States'])
  end
  let(:presenter) { Hyrax::CollectionPresenter.new(document, Ability.new(nil)) }

  before do
    blacklight = ::CatalogController.blacklight_config
    view.define_singleton_method(:blacklight_config) { blacklight }
    view.define_singleton_method(:search_state) { Blacklight::SearchState.new({}, blacklight) }
  end

  # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
  # the link uses f[based_near_sim][]=<URI>, a facet the profile doesn't register (issue #3518).
  it "shows a collection's location by its label, linked through the location facet", flexible: false do
    link = Capybara.string(described_class.new(presenter, view).value(:based_near)).find_link('Bloomington, Indiana, United States')

    expect(CGI.unescape(link['href'])).to include('f[based_near_label_sim][]=Bloomington, Indiana, United States')
  end
end
