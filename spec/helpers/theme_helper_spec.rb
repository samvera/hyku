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

  describe '#theme_file_set_ids' do
    let(:presenter) { double(authorized_file_set_ids: (1..25).map { |i| "fs-#{i}" }) }

    it 'pages at ten entries' do
      paged = helper.theme_file_set_ids(presenter)

      expect(paged.total_count).to eq(25)
      expect(paged.count).to eq(10)
      expect(paged.total_pages).to eq(3)
    end

    it 'clamps an out of range page back to the last page' do
      allow(helper).to receive(:params).and_return({ files_page: '99' })

      expect(helper.theme_file_set_ids(presenter).current_page).to eq(3)
    end

    it 'ignores junk page params' do
      allow(helper).to receive(:params).and_return({ files_page: 'DROP TABLE' })

      expect(helper.theme_file_set_ids(presenter).current_page).to eq(1)
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

  describe '#theme_type_label' do
    it 'prefers the resource type the tenant cataloged' do
      object = double('document', resource_type: ['Thesis'], human_readable_type: 'Generic Work')

      expect(helper.theme_type_label(object)).to eq('Thesis')
    end

    it 'falls back to the model name when no resource type is recorded' do
      object = double('document', resource_type: [], human_readable_type: 'Generic Work')

      expect(helper.theme_type_label(object)).to eq('Generic Work')
    end

    it 'ignores a blank resource type rather than rendering an empty chip' do
      object = double('document', resource_type: ['  '], human_readable_type: 'Generic Work')

      expect(helper.theme_type_label(object)).to eq('Generic Work')
    end
  end

  describe '#theme_license_badge' do
    def badge_for(license)
      helper.theme_license_badge(double('presenter', license: Array(license)))
    end

    it 'shortens a Creative Commons license URL' do
      expect(badge_for('https://creativecommons.org/licenses/by/4.0/')).to eq('CC BY 4.0')
    end

    it 'handles hyphenated codes' do
      expect(badge_for('https://creativecommons.org/licenses/by-nc-nd/3.0/')).to eq('CC BY-NC-ND 3.0')
    end

    it 'recognizes CC0' do
      expect(badge_for('http://creativecommons.org/publicdomain/zero/1.0/')).to eq('CC0 1.0')
    end

    it 'is nil for anything else, so the badge is not rendered' do
      expect(badge_for('http://www.europeana.eu/portal/rights/rr-r.html')).to be_nil
    end

    it 'is nil with no license at all' do
      expect(badge_for(nil)).to be_nil
    end
  end
end
