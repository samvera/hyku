# frozen_string_literal: true

RSpec.describe 'IIIF canvas metadata under a flexible profile', :clean_repo do
  subject(:presenter) do
    Hyrax::IiifManifestPresenter.new(SolrDocument.find(work.id.to_s)).tap do |p|
      p.base_url = 'http://test.host'
      p.file_set_metadata = file_set_metadata
    end
  end

  let!(:schema) do
    Hyrax::FlexibleSchema.create(profile: YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml')))
  end
  let(:page) { image_file_set('Page one') }
  let(:chapter_page) { image_file_set('Chapter page') }
  let(:chapter) do
    flexible(valkyrie_create(:generic_work_resource, title: ['Chapter'], creator: ['Ada'], visibility_setting: 'open', members: [chapter_page]))
  end
  let(:work) do
    flexible(valkyrie_create(:generic_work_resource, title: ['Book'], creator: ['Grace'], visibility_setting: 'open', members: [page, chapter]))
  end

  # The suite boots with HYRAX_FLEXIBLE=false, so records are indexed without a schema version.
  def flexible(resource, extra = {})
    document = Hyrax::SolrService.query("id:#{resource.id}").first.to_h
    Hyrax::SolrService.add(document.merge('schema_version_ssi' => schema.version.to_s).merge(extra), commit: true)
    resource
  end

  def image_file_set(title, visibility = 'open')
    flexible(valkyrie_create(:hyrax_file_set, title: [title], visibility_setting: visibility), 'mime_type_ssi' => 'image/png')
  end

  def manifest
    Hyrax::ManifestBuilderService.new.manifest_for(presenter:)
  end

  def canvas_text(file_set)
    canvas = manifest['items'].find { |item| item['id'].include?(file_set.id.to_s) }
    canvas['metadata']&.flat_map { |field| field['value']['none'] }&.map { |html| Nokogiri::HTML.fragment(html).text }
  end

  include_context 'with displayable file sets'

  before { allow(Flipflop).to receive(:iiif_ranges?).and_return(ranges) }

  before { allow(Hyrax.config).to receive(:flexible?).and_return(true) }

  after { schema.destroy }

  [false, true].each do |ranges_on|
    context "with ranges #{ranges_on ? 'on' : 'off'}" do
      let(:ranges) { ranges_on }

      context 'when the controller turns on file set metadata' do
        let(:file_set_metadata) { true }

        it 'opens the viewer one page at a time, so each panel shows one page' do
          expect(manifest).not_to have_key('viewingHint')
        end

        it "gives the work's own pages their file set metadata only" do
          expect(canvas_text(page)).to include('Page one')
          expect(canvas_text(page)).not_to include('Book', 'Grace')
        end

        it "gives a child work's pages that work's metadata, then the file set's" do
          text = canvas_text(chapter_page)

          expect(text).to include('Chapter', 'Ada', 'Chapter page')
          expect(text.index('Ada')).to be < text.index('Chapter page')
          expect(text).not_to include('Book', 'Grace')
        end
      end

      context 'when the controller leaves file set metadata off' do
        let(:file_set_metadata) { false }

        it 'keeps the paged view' do
          expect(manifest['viewingHint']).to eq 'paged'
        end

        it "leaves the work's own pages to its item metadata" do
          expect(canvas_text(page)).to be_nil
        end

        it "gives a child work's pages the child work's metadata, not the parent's" do
          text = canvas_text(chapter_page)

          expect(text).to include('Chapter', 'Ada')
          expect(text).not_to include('Book', 'Grace', 'Chapter page')
        end
      end
    end
  end

  context 'when the controller turns on file set metadata, with ranges off' do
    let(:ranges) { false }
    let(:file_set_metadata) { true }

    it "builds each page's file set metadata once" do
      allow(Hyku::ProfileManifestMetadata).to receive(:for_file_set).and_call_original

      manifest

      expect(Hyku::ProfileManifestMetadata).to have_received(:for_file_set).exactly(2).times
    end
  end

  [false, true].each do |ranges_on|
    context "when building a manifest with file set metadata on and ranges #{ranges_on ? 'on' : 'off'}" do
      let(:ranges) { ranges_on }
      let(:file_set_metadata) { true }

      it "does not re-read the profile's view definitions for every page" do
        loader = Hyrax::M3SchemaLoader.new
        allow(Hyrax::Schema).to receive(:m3_schema_loader).and_return(loader)
        allow(loader).to receive(:view_definitions_for).and_call_original

        manifest

        # the top-level work's metadata, then one read each for the child works' and the file sets' schemas
        expect(loader).to have_received(:view_definitions_for).exactly(3).times
      end
    end
  end

  context 'when a flexible child work sits under a work indexed without a flexible schema, with ranges on' do
    let(:ranges) { true }
    let(:file_set_metadata) { false }
    let(:work) { valkyrie_create(:generic_work_resource, title: ['Book'], visibility_setting: 'open', members: [page, chapter]) }

    it "still gives the child work's pages its metadata" do
      expect(canvas_text(chapter_page)).to include('Chapter', 'Ada')
    end
  end

  context 'when flexible metadata is turned off for works indexed under a flexible schema' do
    before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

    let(:ranges) { false }
    let(:file_set_metadata) { true }

    it 'leaves the pages and the paged view as they were' do
      expect(canvas_text(chapter_page)).to be_nil
      expect(manifest['viewingHint']).to eq 'paged'
    end
  end

  context 'when a work indexed without a flexible schema has file set metadata turned on' do
    let(:ranges) { false }
    let(:file_set_metadata) { true }
    let(:work) { valkyrie_create(:generic_work_resource, title: ['Book'], visibility_setting: 'open', members: [page, chapter]) }

    it 'keeps the paged view, since its pages carry no file set metadata' do
      expect(manifest['viewingHint']).to eq 'paged'
    end
  end

  context "when one of the work's file sets is also a member of an unrelated work" do
    let(:ranges) { false }
    let(:file_set_metadata) { false }

    before do
      flexible(valkyrie_create(:generic_work_resource, title: ['Unrelated'], visibility_setting: 'open', members: [page]))
    end

    it "keeps the unrelated work's metadata off that page" do
      expect(Array(canvas_text(page))).not_to include('Unrelated')
    end
  end

  context "when looking up the work's descendants" do
    let(:ranges) { false }
    let(:file_set_metadata) { false }

    it 'sends the id list by Hyrax.config.solr_default_method, which defaults to POST' do
      descendant_queries = []
      allow(Hyrax::SolrService).to receive(:query).and_wrap_original do |original, query, **args|
        descendant_queries << args if caller_locations.any? { |location| location.path.end_with?('hyku/profile_manifest.rb') }
        original.call(query, **args)
      end

      manifest

      expect(descendant_queries).to be_present
      expect(descendant_queries).to all(satisfy { |args| !args.key?(:method) })
      expect(Hyrax.config.solr_default_method).to eq :post
    end
  end

  context 'when a work has several child works' do
    let(:ranges) { false }
    let(:file_set_metadata) { false }

    def schema_lookups_for(child_count)
      children = Array.new(child_count) do |i|
        flexible(valkyrie_create(:generic_work_resource, title: ["Chapter #{i}"], visibility_setting: 'open',
                                                         members: [image_file_set("Chapter #{i} page")]))
      end
      parent = flexible(valkyrie_create(:generic_work_resource, title: ['Book'], visibility_setting: 'open', members: children))
      parent_presenter = Hyrax::IiifManifestPresenter.new(SolrDocument.find(parent.id.to_s)).tap { |p| p.base_url = 'http://test.host' }
      lookups = 0
      allow(Hyrax::FlexibleSchema).to receive(:find_by).and_wrap_original do |original, *args, **kwargs|
        lookups += 1
        original.call(*args, **kwargs)
      end
      Hyrax::ManifestBuilderService.new.manifest_for(presenter: parent_presenter)
      lookups
    end

    it 'reads the profile no more often for three child works than for one' do
      expect(schema_lookups_for(3)).to eq schema_lookups_for(1)
    end
  end

  context 'when a private flexible child work sits under a work indexed without a flexible schema, with ranges on' do
    let(:ranges) { true }
    let(:file_set_metadata) { false }
    let(:chapter) do
      flexible(valkyrie_create(:generic_work_resource, title: ['Secret Chapter'], creator: ['Hidden Person'],
                                                       visibility_setting: 'restricted', members: [chapter_page]))
    end
    let(:work) { valkyrie_create(:generic_work_resource, title: ['Book'], visibility_setting: 'open', members: [page, chapter]) }

    it "keeps that work's metadata off its pages in the publicly cached manifest" do
      expect(Array(canvas_text(chapter_page))).not_to include('Secret Chapter', 'Hidden Person')
    end
  end

  context 'when a child work is indexed without a flexible schema, with ranges off' do
    let(:ranges) { false }
    let(:file_set_metadata) { false }
    let(:chapter) do
      valkyrie_create(:generic_work_resource, title: ['Chapter'], description: ['About the chapter'], creator: ['Ada'],
                                              visibility_setting: 'open', members: [chapter_page])
    end

    it "gives its pages IiifPrint's metadata for it, description included" do
      expect(canvas_text(chapter_page)).to include('Chapter', 'About the chapter', 'Ada')
    end
  end

  context 'when a child work indexed without a flexible schema has markup in its values, with ranges off' do
    let(:ranges) { false }
    let(:file_set_metadata) { false }
    let(:chapter) do
      valkyrie_create(:generic_work_resource, title: ['Chapter'], creator: ['<img src=x onerror=alert(1)><script>alert(2)</script>'],
                                              visibility_setting: 'open', members: [chapter_page])
    end

    it 'never puts executable markup on its pages' do
      html = Nokogiri::HTML.fragment(manifest['items'].flat_map { |c| Array(c['metadata']).flat_map { |f| f['value']['none'] } }.join)

      expect(html.css('script')).to be_empty
      expect(html.css('*').flat_map { |node| node.attributes.keys }.grep(/\Aon/i)).to be_empty
    end

    it 'asks IiifPrint for that work as an anonymous visitor would see it' do
      allow(IiifPrint).to receive(:manifest_metadata_for).and_call_original

      manifest

      expect(IiifPrint).to have_received(:manifest_metadata_for)
        .with(hash_including(current_ability: satisfy { |ability| ability.is_a?(::Ability) && ability.current_user.new_record? }))
    end
  end

  context 'when a child work changes after the manifest was built' do
    let(:ranges) { false }
    let(:file_set_metadata) { false }

    it 'gives the manifest a new cache version' do
      before_version = presenter.version
      flexible(chapter, 'system_modified_dtsi' => '2030-01-01T00:00:00Z')

      after_version = Hyrax::IiifManifestPresenter.new(SolrDocument.find(work.id.to_s)).version

      expect(after_version).not_to eq before_version
    end
  end

  context 'when the manifest is built in another locale' do
    let(:ranges) { false }
    let(:file_set_metadata) { false }

    it 'gives it a different cache version, since its labels differ' do
      english = presenter.version
      spanish = I18n.with_locale(:es) { Hyrax::IiifManifestPresenter.new(SolrDocument.find(work.id.to_s)).version }

      expect(spanish).not_to eq english
    end
  end

  context 'when a child work is reindexed without being modified' do
    let(:ranges) { false }
    let(:file_set_metadata) { false }

    it 'gives the manifest a new cache version, since its labels may have changed' do
      before_version = presenter.version
      flexible(chapter, 'creator_label_tesim' => ['Ada Lovelace'])

      after_version = Hyrax::IiifManifestPresenter.new(SolrDocument.find(work.id.to_s)).version

      expect(after_version).not_to eq before_version
    end
  end

  context 'when a grandchild work joins after the work was last indexed, with ranges on' do
    let(:ranges) { true }
    let(:file_set_metadata) { false }
    let(:grand_page) { image_file_set('Grand page') }
    let(:grandchild) do
      flexible(valkyrie_create(:generic_work_resource, title: ['Grandchild'], creator: ['Grace Jr'], visibility_setting: 'open',
                                                       members: [grand_page]))
    end

    before do
      work
      chapter.member_ids += [grandchild.id]
      saved = Hyrax.persister.save(resource: chapter)
      Hyrax.index_adapter.save(resource: saved)
      flexible(saved)
    end

    it "still gives the grandchild's pages its metadata" do
      expect(canvas_text(grand_page)).to include('Grandchild', 'Grace Jr')
    end
  end

  context 'when a child work is not public' do
    let(:ranges) { false }
    let(:file_set_metadata) { false }
    let(:chapter) do
      flexible(valkyrie_create(:generic_work_resource, title: ['Secret Chapter'], creator: ['Hidden Person'],
                                                       visibility_setting: 'restricted', members: [chapter_page]))
    end

    before { presenter.ability = ::Ability.new(nil) }

    it "keeps that work's metadata out of the publicly cached manifest" do
      expect(manifest.to_json).not_to include('Secret Chapter', 'Hidden Person')
    end
  end

  context 'when a page is not public, with file set metadata on' do
    let(:ranges) { false }
    let(:file_set_metadata) { true }
    let(:chapter_page) { image_file_set('Chapter page', 'restricted') }

    it "keeps the file set's own metadata off its page" do
      expect(Array(canvas_text(chapter_page))).not_to include('Chapter page')
    end
  end
end
