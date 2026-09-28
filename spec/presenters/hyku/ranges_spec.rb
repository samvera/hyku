# frozen_string_literal: true

RSpec.describe Hyku::Ranges, :clean_repo do
  subject(:presenter) do
    Hyrax::IiifManifestPresenter.new(SolrDocument.find(work.id.to_s))
  end

  # Bypass the real file-storage stack: prepend a stub that makes every
  # DisplayImagePresenter report a displayable image so the Ranges recursion
  # and TOC structure can be exercised.
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    stub_mod = Module.new do
      def display_image
        IIIFManifest::DisplayImage.new(id.to_s,
                                       width: 640, height: 480,
                                       format: 'image/png',
                                       iiif_endpoint: nil)
      end

      def display_content
        IIIFManifest::V3::DisplayContent.new(id.to_s,
                                             width: 640, height: 480,
                                             type: 'Image')
      end
    end
    Hyrax::IiifManifestPresenter::DisplayImagePresenter.prepend(stub_mod)
  end

  def create_image_file_set
    fs = valkyrie_create(:hyrax_file_set)
    solr_doc = Hyrax::SolrService.query("id:#{fs.id}").first.to_h
    Hyrax::SolrService.add(solr_doc.merge('mime_type_ssi' => 'image/png'), commit: true)
    fs
  end

  let(:file_set) { create_image_file_set }
  let(:second_file_set) { create_image_file_set }

  before do
    allow(Flipflop).to receive(:iiif_ranges?).and_return(true)
    presenter.base_url = 'http://test.host'
  end

  describe '#file_set_presenters' do
    let(:child_work) { valkyrie_create(:generic_work_resource, members: [file_set]) }
    let(:work) { valkyrie_create(:generic_work_resource, members: [child_work, second_file_set]) }

    it "includes its own and its child works' file sets, in member order" do
      expect(presenter.file_set_presenters.map { |p| p.id.to_s })
        .to eq [file_set.id.to_s, second_file_set.id.to_s]
    end

    it 'silently skips non-media file sets' do
      non_media_fs = valkyrie_create(:hyrax_file_set)
      work_with_csv = valkyrie_create(:generic_work_resource, members: [non_media_fs, file_set])
      p = Hyrax::IiifManifestPresenter.new(SolrDocument.find(work_with_csv.id.to_s))
      allow(Flipflop).to receive(:iiif_ranges?).and_return(true)
      p.base_url = 'http://test.host'

      expect(p.file_set_presenters.map { |fp| fp.id.to_s }).to eq [file_set.id.to_s]
    end
  end

  describe '#work_presenters' do
    let(:child_work) { valkyrie_create(:generic_work_resource) }
    let(:work) { valkyrie_create(:generic_work_resource, members: [child_work]) }

    it 'is empty when ranges is enabled' do
      expect(presenter.work_presenters).to be_empty
    end
  end

  describe '#child_work_presenters' do
    let(:work) { valkyrie_create(:generic_work_resource) }

    it('is empty for a work without child works') { expect(presenter.child_work_presenters).to be_empty }

    context 'when the work has member works' do
      let(:child_work) { valkyrie_create(:generic_work_resource) }
      let(:work) { valkyrie_create(:generic_work_resource, members: [child_work]) }

      it 'gives presenters for the work members' do
        expect(presenter.child_work_presenters).not_to be_empty
        expect(presenter.child_work_presenters).to all(be_a(Hyrax::IiifManifestPresenter))
      end
    end
  end

  describe '#ranges' do
    let(:work) { valkyrie_create(:generic_work_resource) }

    it('is empty for a work with no child works') { expect(presenter.ranges).to be_empty }

    context 'when the work has child works with file sets' do
      let(:child_work) { valkyrie_create(:generic_work_resource, title: ['Child'], members: [file_set]) }
      let(:work) { valkyrie_create(:generic_work_resource, title: ['Parent'], members: [child_work, second_file_set]) }

      it 'is empty when the feature is disabled' do
        allow(Flipflop).to receive(:iiif_ranges?).and_return(false)
        expect(presenter.ranges).to be_empty
      end

      it 'gives a top range holding a sub range per member, in member order' do
        expect(presenter.ranges.count).to eq 1

        top = presenter.ranges.first
        expect(top.label).to eq 'Parent'
        expect(top.file_set_presenters).to be_empty

        child_range, file_set_range = top.ranges
        expect(child_range.label).to eq 'Child'
        expect(child_range.file_set_presenters.map { |p| p.id.to_s }).to contain_exactly(file_set.id.to_s)
        expect(file_set_range.file_set_presenters.map { |p| p.id.to_s }).to contain_exactly(second_file_set.id.to_s)
      end
    end
  end

  describe '#version' do
    let(:child_work) { valkyrie_create(:generic_work_resource) }
    let(:work) { valkyrie_create(:generic_work_resource, members: [child_work]) }

    it 'changes when a child work changes' do
      version_before = presenter.version

      child_work.title = ['touched']
      saved = Hyrax.persister.save(resource: child_work)
      Hyrax.index_adapter.save(resource: saved)

      expect(Hyrax::IiifManifestPresenter.new(SolrDocument.find(work.id.to_s)).version)
        .not_to eq version_before
    end
  end

  describe 'cycle detection: mutual parent/child membership' do
    let(:child_work) { valkyrie_create(:generic_work_resource, title: ['Child'], members: [file_set]) }
    let(:work) do
      valkyrie_create(:generic_work_resource, title: ['Parent'], members: [child_work, second_file_set]).tap do |parent|
        child_doc = Hyrax::SolrService.query("id:#{child_work.id}").first.to_h
        child_doc['member_ids_ssim'] = Array(child_doc['member_ids_ssim']) + [parent.id.to_s]
        Hyrax::SolrService.add(child_doc, commit: true)
      end
    end

    it 'includes each file set as a canvas only once' do
      expect(presenter.file_set_presenters.map { |p| p.id.to_s }).to eq [file_set.id.to_s, second_file_set.id.to_s]
    end

    it 'includes each work in the table of contents only once' do
      child_range = presenter.ranges.first.ranges.first

      expect(child_range.label).to eq 'Child'
      expect(child_range.ranges).to be_empty
    end

    it 'includes each work in the cache version tag only once' do
      expect(presenter.version.scan('child_works').count).to eq 2
    end
  end

  describe 'diamond dedup: two child works share the same grandchild' do
    let(:shared_work) { valkyrie_create(:generic_work_resource, title: ['Shared'], members: [file_set]) }
    let(:left_work) { valkyrie_create(:generic_work_resource, title: ['Left'], members: [shared_work]) }
    let(:right_work) { valkyrie_create(:generic_work_resource, title: ['Right'], members: [shared_work]) }
    let(:work) { valkyrie_create(:generic_work_resource, title: ['Parent'], members: [left_work, right_work]) }

    it "includes the shared work's file sets as canvases only once" do
      expect(presenter.file_set_presenters.map { |p| p.id.to_s }).to eq [file_set.id.to_s]
    end
  end

  describe 'manifest generation with child works' do
    let(:child_work) { valkyrie_create(:generic_work_resource, title: ['Child'], creator: ['Bob'], members: [file_set, second_file_set]) }
    let(:work) { valkyrie_create(:generic_work_resource, title: ['Parent'], members: [child_work]) }
    let(:builder_service) { Hyrax::ManifestBuilderService.new }

    it 'generates a manifest rendering child work file sets as canvases' do
      manifest = builder_service.manifest_for(presenter: presenter)

      expect(manifest['type']).to eq 'Manifest'
      expect(manifest['items'].count).to eq 2
    end

    it 'generates a structures block with a range for the child work' do
      manifest = builder_service.manifest_for(presenter: presenter)
      child_range = manifest['structures'].first['items']
                                          .find { |r| r['label']['none'] == ['Child'] }

      expect(child_range['items'].count).to eq 2
    end

    it 'propagates well-formed metadata to child work file set presenters' do
      file_set_ids = [file_set, second_file_set].map { |fs| fs.id.to_s }
      child_fsp = presenter.file_set_presenters.select { |p| file_set_ids.include?(p.id.to_s) }

      expect(child_fsp).to all(satisfy { |p| p.item_metadata.present? })
      child_fsp.first.item_metadata.each do |field|
        expect(field['label']).to be_a(Hash)
        expect(field['value']).to be_a(Hash)
      end
    end
  end
end
