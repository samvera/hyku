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

  describe '#theme_viewer?' do
    it 'is true for a work whose representative loaded' do
      presenter = double(video_embed_viewer?: false, representative_id: 'fs1', representative_presenter: double)

      expect(helper.theme_viewer?(presenter)).to be true
    end

    it 'is false when the representative is one the visitor cannot read' do
      presenter = double(video_embed_viewer?: false, representative_id: 'fs1', representative_presenter: nil)

      expect(helper.theme_viewer?(presenter)).to be_falsey
    end

    it 'is true for an embedded video even with no representative' do
      presenter = double(video_embed_viewer?: true)

      expect(helper.theme_viewer?(presenter)).to be true
    end
  end

  describe '#theme_luminance' do
    it 'reads a dark brand color as dark' do
      expect(helper.theme_luminance('#3c3c3c')).to be < 0.22
    end

    it 'reads a mid grey as already too light for a dark ramp' do
      expect(helper.theme_luminance('#808080')).to be > 0.0631
    end

    it 'keeps a dark brand grey under the ramp ceiling' do
      expect(helper.theme_luminance('#454545')).to be <= 0.0631
    end

    it 'treats a value it cannot read as dark' do
      expect(helper.theme_luminance('rgb(0,0,0)')).to eq(0)
    end
  end

  describe '#theme_brand_mix' do
    it 'keeps the design value for a brand colour that already clears the floor' do
      expect(helper.theme_brand_mix('#2e74b2')).to eq(55)
    end

    it 'lifts a near-black brand colour further' do
      expect(helper.theme_brand_mix('#000000')).to be < 55
    end

    it 'lands a near-black brand colour above the floor' do
      percent = helper.theme_brand_mix('#000000')
      lifted = (255 * (100 - percent)) / 100

      expect(helper.theme_luminance(format('#%02x%02x%02x', lifted, lifted, lifted))).to be >= 0.31
    end
  end

  describe '#theme_brand_mix with junk input' do
    it 'falls back to the design value rather than raising' do
      expect(helper.theme_brand_mix('#fff')).to eq(55)
    end
  end

  describe '#theme_readable_ink' do
    it 'puts light ink on a dark accent' do
      expect(helper.theme_readable_ink('#2e74b2')).to eq('#ffffff')
    end

    it 'puts dark ink on a light accent' do
      expect(helper.theme_readable_ink('#ffeb3b')).to eq('#000000')
    end

    it 'falls back to light ink for a value it cannot read' do
      expect(helper.theme_readable_ink('rgb(0,0,0)')).to eq('#ffffff')
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
