# frozen_string_literal: true

RSpec.describe Hyku::FileSetMetadata do
  subject(:presenter) { Hyrax::IiifManifestPresenter.new(SolrDocument.new(id: 'w1', has_model_ssim: ['GenericWork'])) }

  let(:file_set) { SolrDocument.new(id: 'fs1', has_model_ssim: ['FileSet'], mime_type_ssi: 'image/jpeg') }
  let(:page) do
    Hyrax::IiifManifestPresenter::DisplayImagePresenter.new(file_set).tap do |p|
      allow(p).to receive(:display_content).and_return(instance_double(IIIFManifest::V3::DisplayContent))
    end
  end
  let(:page_metadata) { [{ 'label' => { 'en' => ['Title'] }, 'value' => { 'none' => ['Page one'] } }] }

  before do
    stub_const('IiifPrint::Flexibility', class_double('IiifPrint::Flexibility', applies_to?: true))
    allow(presenter).to receive(:member_presenters).and_return([page])
    allow(IiifPrint).to receive(:manifest_metadata_from).with(work: file_set, presenter: presenter).and_return(page_metadata)
  end

  it 'leaves the pages alone by default' do
    expect(presenter.file_set_presenters.first.item_metadata).to be_nil
    expect(IiifPrint).not_to have_received(:manifest_metadata_from)
  end

  describe '#version' do
    let(:newest_change) { '2026-10-06T09:13:44Z' }

    before do
      allow(presenter).to receive(:member_ids).and_return(%w[fs1 fs2])
      allow(Hyrax::SolrService).to receive(:query)
        .with('{!terms f=id}fs1,fs2', fl: 'system_modified_dtsi', sort: 'system_modified_dtsi desc', rows: 1, method: :post)
        .and_return([SolrHit.new('system_modified_dtsi' => newest_change)])
    end

    it("is the work's own by default") { expect(presenter.version).not_to include newest_change }

    it 'follows the newest change to any member once the work type opts in, so an edited page is not served stale' do
      presenter.iiif_file_set_metadata = true
      expect(presenter.version).to include newest_change
    end

    it 'asks Solr once, however often the version is asked for' do
      presenter.iiif_file_set_metadata = true
      2.times { presenter.version }
      expect(Hyrax::SolrService).to have_received(:query).once
    end

    context "with IIIF ranges on, where a child work's pages are the work's too" do
      let(:newest_child_change) { '2026-10-06T10:00:00Z' }
      let(:child) { Hyrax::IiifManifestPresenter.new(SolrDocument.new(id: 'c1', has_model_ssim: ['GenericWork'])) }

      before do
        allow(Flipflop).to receive(:iiif_ranges?).and_return(true)
        allow(child).to receive_messages(member_ids: %w[fs3], child_work_presenters: [presenter])
        allow(presenter).to receive(:child_work_presenters).and_return([child])
        allow(Hyrax::SolrService).to receive(:query)
          .with('{!terms f=id}fs1,fs2,fs3', fl: 'system_modified_dtsi', sort: 'system_modified_dtsi desc', rows: 1, method: :post)
          .and_return([SolrHit.new('system_modified_dtsi' => newest_child_change)])
      end

      it "follows the newest change to a child work's member as well, once, even when the child lists the work" do
        presenter.iiif_file_set_metadata = true
        expect(presenter.version).to include newest_child_change
      end
    end
  end

  context 'when the work type opts in' do
    before { presenter.iiif_file_set_metadata = true }

    it "gives each page its file set's metadata" do
      expect(presenter.file_set_presenters.first.item_metadata).to eq page_metadata
    end

    it 'builds each page once per manifest, however often the pages are asked for' do
      2.times { presenter.file_set_presenters }
      expect(IiifPrint).to have_received(:manifest_metadata_from).once
    end

    context 'when the file set has no metadata profile' do
      before { allow(IiifPrint::Flexibility).to receive(:applies_to?).with(file_set).and_return(false) }

      it "leaves the page alone, since IiifPrint's configured fields are work fields" do
        expect(presenter.file_set_presenters.first.item_metadata).to be_blank
        expect(IiifPrint).not_to have_received(:manifest_metadata_from)
      end
    end

    context 'when IiifPrint cannot read a metadata profile' do
      before { hide_const('IiifPrint::Flexibility') }

      it('leaves the page alone') { expect(presenter.file_set_presenters.first.item_metadata).to be_blank }
    end

    context 'when the file set is restricted' do
      before { allow(::Ability).to receive(:new).and_return(instance_double(Ability, can?: false)) }

      it "still gives the page its file set's metadata, as an anonymous visitor would see it" do
        expect(presenter.file_set_presenters.first.item_metadata).to eq page_metadata
      end
    end

    context 'with IIIF ranges on, where Hyku::Ranges sets the pages up' do
      let(:ranges_metadata) { [{ 'label' => { 'en' => ['Abstract'] }, 'value' => { 'none' => ['Work abstract'] } }] }

      before do
        allow(Flipflop).to receive(:iiif_ranges?).and_return(true)
        allow(presenter).to receive(:item_metadata).and_return(ranges_metadata)
      end

      it "ends each page with its file set's metadata" do
        expect(presenter.file_set_presenters.first.item_metadata.last(page_metadata.size)).to eq page_metadata
      end
    end

    context "on a child work's page, which already carries that child's metadata" do
      let(:child_metadata) { [{ 'label' => { 'en' => ['Title'] }, 'value' => { 'none' => ['Volume 2'] } }] }

      before { page.item_metadata = child_metadata }

      it "follows it with the file set's metadata" do
        expect(presenter.file_set_presenters.first.item_metadata).to eq child_metadata + page_metadata
      end

      it 'does not repeat it when the pages are asked for again' do
        2.times { presenter.file_set_presenters }
        expect(page.item_metadata).to eq child_metadata + page_metadata
      end
    end
  end
end
