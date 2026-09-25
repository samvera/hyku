# frozen_string_literal: true

# Pins the label rendering Hyku relies on Hyrax for, so a Hyku override cannot
# quietly reclaim it.
RSpec.describe 'controlled label rendering' do
  let(:labels) { { 'oer' => 'OER' } }

  def rendered(klass, field, values, options = {})
    klass.new(field, values, { labels: labels }.merge(options)).render.to_s
  end

  it 'shows the label rather than the stored id' do
    html = rendered(Hyrax::Renderers::AttributeRenderer, :resource_type, ['oer'])

    expect(html).to include 'OER'
    expect(html).not_to include '>oer<'
  end

  describe 'a property rendered as a search link' do
    subject(:html) { rendered(Hyrax::Renderers::LinkedAttributeRenderer, :resource_type, ['oer']) }

    it 'shows the label as the link text' do
      expect(html).to include 'OER'
    end

    it 'searches on the stored id, which is what the index holds' do
      expect(html).to include 'q=oer'
    end
  end

  describe 'a property rendered as a facet link' do
    subject(:html) { rendered(Hyrax::Renderers::FacetedAttributeRenderer, :resource_type, ['oer']) }

    it 'shows the label as the link text' do
      expect(html).to include 'OER'
    end

    it 'filters on the id facet, which is what the index holds' do
      expect(html).to include 'resource_type_sim'
    end
  end

  it 'links a URI-valued license to its id under the label' do
    uri = 'http://creativecommons.org/licenses/by/3.0/us/'
    html = Hyrax::Renderers::LicenseAttributeRenderer
           .new(:license, [uri], labels: { uri => 'Attribution 3.0 United States' }).render.to_s

    expect(html).to include(%(href="#{uri}")).and include('Attribution 3.0 United States')
  end

  it 'renders a work indexed before labels existed unchanged' do
    expect(rendered(Hyrax::Renderers::AttributeRenderer, :resource_type, ['oer'], labels: nil))
      .to include 'oer'
  end
end
