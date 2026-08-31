# frozen_string_literal: true

RSpec.describe Hyrax::Renderers::AttributeRendererDecorator do
  let(:renderer) { Hyrax::Renderers::AttributeRenderer.new(field, values, options) }
  let(:field) { :resource_type }
  let(:rendered) { renderer.render }

  context 'with labels for opaque ids' do
    let(:values) { ['local_auth_123'] }
    let(:options) { { labels: ['Opaque Term'] } }

    it 'shows the label' do
      expect(rendered).to include 'Opaque Term'
    end

    it 'does not show the stored id' do
      expect(rendered).not_to include 'local_auth_123'
    end

    it 'does not link, since the id is not a URI' do
      expect(rendered).not_to include '<a href'
    end
  end

  # keyword carries itemprop="keywords" upstream, and a controlled keyword is a
  # real profile configuration -- so structured data has to survive the label swap.
  context 'for a field configured with microdata' do
    let(:field) { :keyword }
    let(:values) { ['local_auth_123'] }
    let(:options) { { labels: ['Opaque Term'] } }

    it 'keeps the itemprop while showing the label' do
      expect(rendered).to include 'itemprop="keywords"'
      expect(rendered).to include 'Opaque Term'
    end
  end

  context 'with a label for a URI id' do
    let(:field) { :license }
    let(:values) { ['http://creativecommons.org/licenses/by/3.0/us/'] }
    let(:options) { { labels: ['Attribution 3.0 United States'] } }

    it 'shows the label as the link text' do
      expect(rendered).to include '>Attribution 3.0 United States<'
    end

    it 'links to the stored id' do
      expect(rendered).to include 'href="http://creativecommons.org/licenses/by/3.0/us/"'
    end

    it 'opens the link safely in a new tab' do
      expect(rendered).to include 'rel="noopener noreferrer"'
    end
  end

  context 'with a value that resolved to no label' do
    let(:values) { ['known_id', 'unresolved_id'] }
    let(:options) { { labels: ['Known Term', 'unresolved_id'] } }

    it 'shows the label for the value that resolved' do
      expect(rendered).to include 'Known Term'
    end

    it 'falls back to the raw value for the one that did not' do
      expect(rendered).to include 'unresolved_id'
    end
  end

  context 'when the values are sorted for display' do
    let(:values) { ['zzz_id', 'aaa_id'] }
    let(:options) { { labels: ['Zebra', 'Aardvark'], sort: true } }

    it 'keeps each label with its own value rather than its original position' do
      expect(rendered.index('Aardvark')).to be < rendered.index('Zebra')
    end
  end

  context 'without labels' do
    let(:values) { ['local_auth_123'] }
    let(:options) { {} }

    it 'renders the stored value unchanged' do
      expect(rendered).to include 'local_auth_123'
    end
  end

  context 'for a free-text field' do
    let(:field) { :abstract }
    let(:values) { ['An *emphasized* abstract'] }
    let(:options) { {} }

    it 'routes through the markdown path untouched' do
      allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(true)

      expect(rendered).to include '<em>emphasized</em>'
    end
  end
end
