# frozen_string_literal: true

RSpec.describe Hyku::ThumbnailPresenter, type: :helper do
  let(:own_cname) { 'dev-hyku.localhost.direct' }
  let(:path) { '/downloads/abc123?file=thumbnail' }

  def presenter_for(extra = {})
    doc = SolrDocument.new({ 'id' => 'abc123',
                             'has_model_ssim' => ['GenericWork'],
                             'thumbnail_path_ss' => path }.merge(extra))
    helper.document_presenter(doc).thumbnail
  end

  before do
    without_partial_double_verification do
      allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      allow(helper).to receive(:document_index_view_type).and_return(:list)
      allow(helper).to receive(:current_account).and_return(instance_double(Account, cname: own_cname))
    end
  end

  describe '#url' do
    it 'prefixes the cname for a document from another tenant' do
      expect(presenter_for('account_cname_tesim' => ['other-tenant.example.org']).url)
        .to eq("http://other-tenant.example.org#{path}")
    end

    it 'leaves the path relative for a document from this tenant' do
      expect(presenter_for('account_cname_tesim' => [own_cname]).url).to eq(path)
    end

    it 'leaves the path relative when the document has no cname' do
      expect(presenter_for.url).to eq(path)
    end
  end

  describe '#thumbnail_tag' do
    it 'defers offscreen thumbnails to the browser' do
      expect(presenter_for.thumbnail_tag({}, suppress_link: true)).to include('loading="lazy"')
    end

    it 'lets a caller opt a thumbnail out of lazy loading' do
      expect(presenter_for.thumbnail_tag({ loading: 'eager' }, suppress_link: true))
        .to include('loading="eager"')
    end

    it 'carries the cross-tenant cname into the img src' do
      expect(presenter_for('account_cname_tesim' => ['other-tenant.example.org'])
               .thumbnail_tag({}, suppress_link: true))
        .to include(%(src="http://other-tenant.example.org#{path}"))
    end
  end

  describe '#exists?' do
    it 'is true when the document carries a thumbnail' do
      expect(presenter_for.exists?).to be true
    end

    it 'is false when the document has no thumbnail, so gallery views can fall back' do
      doc = SolrDocument.new('id' => 'abc123', 'has_model_ssim' => ['GenericWork'])
      expect(helper.document_presenter(doc).thumbnail.exists?).to be false
    end
  end
end
