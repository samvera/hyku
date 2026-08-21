# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThemeHelper, type: :helper do
  describe '#theme_plain_text' do
    it 'strips tags revealed by unescaping so they cannot reconstitute as markup' do
      result = helper.theme_plain_text('&lt;b&gt;bold&lt;/b&gt;')

      expect(result).to eq('bold')
      expect(result).not_to include('<')
    end

    it 'leaves an ampersand for the template to escape once' do
      expect(helper.theme_plain_text('Sound &amp; Vision')).to eq('Sound & Vision')
    end

    it 'hands a double-encoded tag back as text that the template escapes' do
      result = helper.theme_plain_text('&amp;lt;img src=x onerror=1&amp;gt;')

      expect(result).to eq('<img src=x onerror=1>')
      expect(ERB::Util.html_escape(result)).to eq('&lt;img src=x onerror=1&gt;')
    end

    it 'keeps a space where a tag was so words do not run together' do
      expect(helper.theme_plain_text('<p>One</p><p>Two</p>')).to eq('One Two')
    end
  end

  describe '#theme_blurb' do
    it 'truncates on a word boundary' do
      blurb = helper.theme_blurb('<p>A long enough description to be cut somewhere.</p>', length: 20)

      expect(blurb).to end_with('...')
      expect(blurb.length).to be <= 20
    end

    it 'returns nothing for blank text' do
      expect(helper.theme_blurb('', length: 20)).to be_nil
    end
  end

  describe '#theme_readable_ids' do
    it 'returns nothing without asking Solr when given no ids' do
      expect(helper.theme_readable_ids([])).to eq([])
    end

    it 'keeps only the ids the access-filtered search returns' do
      documents = [double(id: 'readable')]
      helper.instance_variable_set(:@search_service, double(fetch: [nil, documents]))

      expect(helper.theme_readable_ids(%w[readable hidden])).to eq(['readable'])
    end
  end

  describe '#theme_thumbnail_url' do
    before do
      allow(Site).to receive(:instance)
        .and_return(double(default_work_image: nil, default_collection_image: nil))
    end

    it 'uses the indexed derivative when present' do
      document = SolrDocument.new('thumbnail_path_ss' => '/downloads/abc?file=thumbnail')

      expect(helper.theme_thumbnail_url(document)).to eq('/downloads/abc?file=thumbnail')
    end

    it 'prefers the tenant default over a bundled placeholder' do
      allow(Site).to receive(:instance)
        .and_return(double(default_work_image: double(url: '/uploads/work.jpg'), default_collection_image: nil))
      document = SolrDocument.new('thumbnail_path_ss' => '/assets/audio-abc.png')

      expect(helper.theme_thumbnail_url(document)).to eq('/uploads/work.jpg')
    end

    it 'keeps the indexed placeholder when no tenant default is set, since it matches the media type' do
      document = SolrDocument.new('thumbnail_path_ss' => '/assets/audio-abc.png')

      expect(helper.theme_thumbnail_url(document)).to eq('/assets/audio-abc.png')
    end

    it 'falls back to the default image when nothing is indexed' do
      expect(helper.theme_thumbnail_url(SolrDocument.new)).to include('default')
    end

    it 'leaves a collection with the generic default rather than a media placeholder' do
      document = SolrDocument.new('thumbnail_path_ss' => '/assets/audio-abc.png')

      expect(helper.theme_thumbnail_url(document, default: :collection)).to include('default')
    end

    it 'takes the collection default when asked for one' do
      allow(Site).to receive(:instance)
        .and_return(double(default_work_image: nil, default_collection_image: double(url: '/uploads/coll.jpg')))

      expect(helper.theme_thumbnail_url(SolrDocument.new, default: :collection)).to eq('/uploads/coll.jpg')
    end

    it 'takes the work default otherwise' do
      allow(Site).to receive(:instance)
        .and_return(double(default_work_image: double(url: '/uploads/work.jpg'), default_collection_image: nil))

      expect(helper.theme_thumbnail_url(SolrDocument.new)).to eq('/uploads/work.jpg')
    end
  end
end
