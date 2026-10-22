# frozen_string_literal: true

RSpec.describe Hyku::ViewingHint, flexible: :either do
  subject(:presenter) do
    Hyrax::IiifManifestPresenter.new(SolrDocument.new(id: 'w1', has_model_ssim: ['GenericWork'], title_tesim: ['A work'],
                                                      system_modified_dtsi: '2026-10-14T00:00:00Z'))
  end

  before { presenter.hostname = 'test.host' }

  it 'asks viewers for facing pages by default' do
    expect(presenter.viewing_hint).to eq ['paged']
  end

  it "follows the application's default" do
    allow(described_class).to receive(:default_viewing_hint).and_return('continuous')

    expect(presenter.viewing_hint).to eq ['continuous']
  end

  it 'leaves the hint out when the work type sets none' do
    presenter.iiif_viewing_hint = nil

    expect(presenter.viewing_hint).to be_nil
  end

  it 'gives a IIIF v2 manifest the hint as it is' do
    presenter.iiif_version = 2

    expect(presenter.viewing_hint).to eq 'paged'
  end

  describe 'the manifest a builder writes' do
    subject(:manifest) { service.manifest_for(presenter:) }

    before do
      allow(presenter).to receive_messages(manifest_url: 'http://test.host/concern/generic_works/w1/manifest', homepage: [])
      allow(Flipflop).to receive(:iiif_ranges?).and_return(true)
    end

    context 'with a IIIF v2 factory' do
      let(:service) { Hyrax::ManifestBuilderService.new(version: 2, iiif_manifest_factory: IIIFManifest::ManifestFactory) }

      it('carries the hint as a viewingHint') { expect(manifest).to include('viewingHint' => 'paged') }
    end

    context 'with a IIIF v3 factory, whatever IiifPrint is configured for' do
      let(:service) { Hyrax::ManifestBuilderService.new(version: 2, iiif_manifest_factory: IIIFManifest::V3::ManifestFactory) }

      it('carries the hint as a list') { expect(manifest).to include('behavior' => ['paged']) }
    end

    context 'with an app\'s own IIIF v3 factory' do
      let(:service) { Hyrax::ManifestBuilderService.new(version: 2, iiif_manifest_factory: Class.new(IIIFManifest::V3::ManifestFactory)) }

      it('carries the hint as a list') { expect(manifest).to include('behavior' => ['paged']) }
    end
  end

  it "changes the manifest's version when the hint changes" do
    paged = presenter.version
    presenter.iiif_viewing_hint = nil

    expect(presenter.version).not_to eq paged
  end

  describe 'the v3 manifest' do
    [true, false].each do |ranges|
      context "with IIIF ranges #{ranges ? 'on' : 'off'}" do
        subject(:manifest) { Hyrax::ManifestBuilderService.new.manifest_for(presenter:) }

        before do
          allow(Flipflop).to receive(:iiif_ranges?).and_return(ranges)
          allow(presenter).to receive_messages(manifest_url: 'http://test.host/concern/generic_works/w1/manifest',
                                               homepage: [])
        end

        it 'carries the hint as a behavior, never as a viewingHint' do
          expect(manifest).to include('behavior' => ['paged'])
          expect(manifest).not_to have_key('viewingHint')
        end

        it 'carries neither when the work type sets no hint' do
          presenter.iiif_viewing_hint = nil

          expect(manifest.keys).not_to include('behavior', 'viewingHint')
        end
      end
    end
  end
end
