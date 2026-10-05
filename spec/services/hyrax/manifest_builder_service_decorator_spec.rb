# frozen_string_literal: true

RSpec.describe Hyrax::ManifestBuilderServiceDecorator do
  subject(:service) { Hyrax::ManifestBuilderService.new }

  describe 'sanitizing manifest strings with ranges on' do
    def sanitized(text)
      service.send(:deep_sanitize, 'metadata' => [text])['metadata'].first
    end

    it 'never turns escaped markup into a tag' do
      expect(sanitized('&lt;script&gt;alert(1)&lt;/script&gt;Cats')).not_to include '<script'
    end

    it 'never turns escaped user text into a link' do
      expect(sanitized('&lt;a href="http://evil.example"&gt;click&lt;/a&gt;')).not_to include '<a href'
    end

    it 'keeps text that contains angle brackets' do
      expect(sanitized('a&lt;b and c&gt;d')).to eq 'a&lt;b and c&gt;d'
    end

    it 'keeps links' do
      expect(sanitized('<a href="https://example.com">Cats</a>')).to eq '<a href="https://example.com">Cats</a>'
    end

    it 'shows an ampersand as itself' do
      expect(sanitized('Tom &amp; Jerry')).to eq 'Tom & Jerry'
    end
  end

  describe 'sanitizing canvas labels with ranges off' do
    def sanitized_label(text)
      service.instance_variable_set(:@child_works, [])
      hash = { 'items' => [{ 'id' => 'http://test.host/canvas/fs-1', 'label' => { 'none' => [text.dup] } }] }
      service.send(:sanitize_v3, hash:, presenter: nil, solr_doc_hits: nil)['items'].first['label']['none'].first
    end

    it 'never turns escaped markup into a tag' do
      expect(sanitized_label('&lt;script&gt;alert(1)&lt;/script&gt;Cats')).not_to include '<script'
    end

    it 'never turns an escaped link or image into one' do
      expect(sanitized_label('&lt;a href="https://evil.example"&gt;click&lt;/a&gt; &lt;img src="https://evil.example/x.png"&gt;'))
        .not_to include('<a href', '<img')
    end

    it 'never turns doubly escaped markup into a tag' do
      expect(sanitized_label('&amp;lt;script&amp;gt;alert(1)&amp;lt;/script&amp;gt;Cats')).not_to include '<script'
    end

    it 'shows an ampersand as itself' do
      expect(sanitized_label('Tom &amp; Jerry')).to eq 'Tom & Jerry'
    end
  end
end
