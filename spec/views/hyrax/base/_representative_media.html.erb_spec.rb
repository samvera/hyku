# frozen_string_literal: true

RSpec.describe 'hyrax/base/_representative_media.html.erb', type: :view do
  let(:file_set_presenter) { double('file set presenter') }
  let(:presenter) do
    double('work show presenter',
           representative_id: 'fs1',
           representative_presenter: file_set_presenter,
           iiif_viewer?: iiif,
           show_pdf_viewer?: false,
           manifest_url: 'https://example-tenant.test/concern/generic_works/abc/manifest')
  end

  before do
    allow(view).to receive(:iiif_viewer_display).and_return('<div class="uv"></div>'.html_safe)
  end

  context 'when the work renders in the IIIF viewer' do
    let(:iiif) { true }

    before { render partial: 'hyrax/base/representative_media', locals: { presenter:, viewer: true } }

    it 'shows a visible IIIF manifest link pointing at the manifest' do
      expect(rendered).to have_link(t('hyku.work_show.iiif_manifest'),
                                    href: 'https://example-tenant.test/concern/generic_works/abc/manifest')
    end
  end

  context 'when the work has no IIIF viewer' do
    let(:iiif) { false }

    before do
      allow(view).to receive(:media_display_partial).and_return('hyrax/file_sets/media_display/default')
      stub_template 'hyrax/file_sets/media_display/_default.html.erb' => ''
      render partial: 'hyrax/base/representative_media', locals: { presenter:, viewer: true }
    end

    it 'does not show a manifest link' do
      expect(rendered).not_to have_link(t('hyku.work_show.iiif_manifest'))
    end
  end
end
