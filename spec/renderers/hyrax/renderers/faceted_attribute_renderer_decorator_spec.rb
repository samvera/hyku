# frozen_string_literal: true

RSpec.describe Hyrax::Renderers::FacetedAttributeRendererDecorator do
  def query_for(**options)
    renderer = Hyrax::Renderers::FacetedAttributeRenderer.new(:resource_type, ['Article'], labels: { 'Article' => 'Article' }, **options)
    URI.parse(Nokogiri::HTML(renderer.render).at_css('a')['href']).query
  end

  it 'links a term whose label is its id to the label facet the catalog registers' do
    expect(query_for(label_facet_registered: true)).to include CGI.escape('f[resource_type_label_sim][]')
  end

  it 'links to the id facet when the caller does not say the label facet is registered' do
    expect(query_for).to include CGI.escape('f[resource_type_sim][]')
  end
end
