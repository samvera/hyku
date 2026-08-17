# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeritageHelper, type: :helper do
  describe '#hrt_blurb' do
    it 'strips markup and truncates on a word boundary' do
      text = "<p>#{'A long descriptive sentence about the object. ' * 10}</p>"

      blurb = helper.hrt_blurb(text, length: 50)

      expect(blurb.length).to be <= 50
      expect(blurb).not_to include('<p>')
    end

    it 'returns nil for blank text' do
      expect(helper.hrt_blurb('')).to be_nil
    end
  end

  describe '#hrt_file_set_ids' do
    let(:presenter) { double(authorized_file_set_ids: (1..25).map { |i| "fs-#{i}" }) }

    it 'pages at ten entries' do
      paged = helper.hrt_file_set_ids(presenter)

      expect(paged.total_count).to eq(25)
      expect(paged.count).to eq(10)
      expect(paged.total_pages).to eq(3)
    end

    it 'clamps an out of range page back to the last page' do
      allow(helper).to receive(:params).and_return({ files_page: '99' })

      expect(helper.hrt_file_set_ids(presenter).current_page).to eq(3)
    end

    it 'ignores junk page params' do
      allow(helper).to receive(:params).and_return({ files_page: 'DROP TABLE' })

      expect(helper.hrt_file_set_ids(presenter).current_page).to eq(1)
    end
  end

  describe '#hrt_viewer?' do
    it 'is true with a representative present' do
      presenter = double(video_embed_viewer?: false, representative_id: 'abc', representative_presenter: double)

      expect(helper.hrt_viewer?(presenter)).to be true
    end

    it 'is false with nothing to show' do
      presenter = double(video_embed_viewer?: false, representative_id: nil)

      expect(helper.hrt_viewer?(presenter)).to be false
    end
  end

  describe '#hrt_collection_thumbnail_tag' do
    before { allow(Site).to receive(:instance).and_return(double(default_collection_image: nil)) }

    it 'uses the indexed branding thumbnail when present' do
      document = SolrDocument.new('thumbnail_path_ss' => '/uploads/brand.jpg')

      expect(helper.hrt_collection_thumbnail_tag(document)).to include('/uploads/brand.jpg')
    end

    it 'ignores a bundled placeholder and falls back to the default image' do
      document = SolrDocument.new('thumbnail_path_ss' => '/assets/collection-abc.png')

      tag = helper.hrt_collection_thumbnail_tag(document)

      expect(tag).not_to include('collection-abc')
      expect(tag).to include('default')
    end

    it 'falls back to the default image when there is no thumbnail' do
      expect(helper.hrt_collection_thumbnail_tag(SolrDocument.new)).to include('default')
    end
  end

  describe '#hrt_plain_text' do
    it 'strips tags revealed by unescaping so they cannot reconstitute as markup' do
      result = helper.hrt_plain_text('&lt;b&gt;bold&lt;/b&gt;')

      expect(result).to eq('bold')
      expect(result).not_to include('<')
    end
  end
end
