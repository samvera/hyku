# frozen_string_literal: true

RSpec.describe Blacklight::CatalogHelperBehaviorDecorator, type: :helper do
  let(:own_cname) { 'dev-hyku.localhost.direct' }
  let(:path) { '/downloads/abc123?file=thumbnail' }
  let(:document) do
    SolrDocument.new('id' => 'abc123',
                     'has_model_ssim' => ['GenericWork'],
                     'thumbnail_path_ss' => path,
                     'account_cname_tesim' => ['other-tenant.example.org'])
  end

  before do
    without_partial_double_verification do
      allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      allow(helper).to receive(:document_index_view_type).and_return(:list)
      allow(helper).to receive(:current_account).and_return(instance_double(Account, cname: own_cname))
    end
  end

  describe '#thumbnail_url' do
    it 'returns the presenter url, cname and all' do
      expect(helper.thumbnail_url(document)).to eq("http://other-tenant.example.org#{path}")
    end

    it 'accepts anything that wraps a solr document' do
      wrapper = double(solr_document: document) # rubocop:disable RSpec/VerifiedDoubles
      expect(helper.thumbnail_url(wrapper)).to eq(helper.thumbnail_url(document))
    end
  end

  describe '#render_thumbnail_tag' do
    it 'renders the same markup as the presenter it delegates to' do
      expect(helper.render_thumbnail_tag(document, {}, suppress_link: true))
        .to eq(helper.document_presenter(document).thumbnail.thumbnail_tag({}, suppress_link: true))
    end

    it 'carries the cross-tenant cname and defers offscreen images' do
      tag = helper.render_thumbnail_tag(document, { alt: 'x' }, suppress_link: true)
      expect(tag).to include(%(src="http://other-tenant.example.org#{path}"))
      expect(tag).to include('loading="lazy"')
    end
  end
end
