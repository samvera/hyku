# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PracticeResearchHelper, type: :helper do
  describe '#pr_card_blurb' do
    it 'uses the description' do
      presenter = double('presenter', description: ['A commission for Dairy Primary School.'])

      expect(helper.pr_card_blurb(presenter)).to eq('A commission for Dairy Primary School.')
    end

    it 'puts a space between paragraphs instead of running them together' do
      presenter = double('presenter', description: ['<p>Six lighthouses.</p><p>The portfolio gathers.</p>'])

      expect(helper.pr_card_blurb(presenter)).to eq('Six lighthouses. The portfolio gathers.')
    end

    it 'keeps prose comparisons that only look like tags' do
      expect(helper.pr_plain_text('Editions <50 and >10 available.')).to eq('Editions <50 and >10 available.')
    end

    it 'truncates on a word boundary' do
      presenter = double('presenter', description: ["#{'word ' * 40}end"])

      blurb = helper.pr_card_blurb(presenter, length: 30)

      expect(blurb.length).to be <= 30
      expect(blurb).to end_with('...')
    end

    it 'is nil when the work has no description' do
      presenter = double('presenter', description: [])

      expect(helper.pr_card_blurb(presenter)).to be_nil
    end
  end

  describe '#pr_thumbnail?' do
    it 'is false for the Hyrax placeholder image, so the card shows the stripe instead' do
      presenter = double('presenter', thumbnail_path: Hyrax::ThumbnailPathService.default_image)

      expect(helper.pr_thumbnail?(presenter)).to be(false)
    end

    it 'is true for a real derivative' do
      presenter = double('presenter', thumbnail_path: '/downloads/abc123?file=thumbnail')

      expect(helper.pr_thumbnail?(presenter)).to be(true)
    end

    it 'is false when there is no path at all, rather than rendering a broken image' do
      presenter = double('presenter', thumbnail_path: nil)

      expect(helper.pr_thumbnail?(presenter)).to be(false)
    end
  end

  describe '#pr_contributor_summary' do
    def document(participants: nil, creators: nil)
      SolrDocument.new(
        { 'participants_json_ss' => participants&.to_json, 'creator_tesim' => creators }.compact
      )
    end

    it 'names one participant' do
      doc = document(participants: [{ 'name' => 'Bruce McLean' }])

      expect(helper.pr_contributor_summary(doc)).to eq('Bruce McLean')
    end

    it 'names two' do
      doc = document(participants: [{ 'name' => 'Bruce McLean' }, { 'name' => 'Jayne Osgood' }])

      expect(helper.pr_contributor_summary(doc)).to eq('Bruce McLean and Jayne Osgood')
    end

    it 'counts the rest beyond two, separating inverted names with a semicolon' do
      doc = document(participants: [{ 'name' => 'Achebe, Ngozi' }, { 'name' => 'Okonkwo, Adaeze' },
                                    { 'name' => 'White, Neal' }])

      expect(helper.pr_contributor_summary(doc)).to eq('Achebe, Ngozi; Okonkwo, Adaeze and 1 other')
    end

    it 'falls back to creators when the work has no participants' do
      doc = document(creators: ['Neal White'])

      expect(helper.pr_contributor_summary(doc)).to eq('Neal White')
    end

    it 'is nil when the work credits nobody, so the card drops the line' do
      expect(helper.pr_contributor_summary(document)).to be_nil
    end

    it 'survives a malformed participants blob' do
      doc = SolrDocument.new('participants_json_ss' => 'not json', 'creator_tesim' => ['Ama Boateng'])

      expect(helper.pr_contributor_summary(doc)).to eq('Ama Boateng')
    end
  end

  describe '#pr_featured_researcher?' do
    it 'is false for a blank content block, so the module hides' do
      assign(:featured_researcher, double(value: ''))

      expect(helper.pr_featured_researcher?).to be(false)
    end

    it 'is true once an admin has written one' do
      assign(:featured_researcher, double(value: '<p>Jayne Osgood</p>'))

      expect(helper.pr_featured_researcher?).to be(true)
    end
  end

  describe '#pr_section_present?' do
    it 'is false for a fragment whose tags carry no text' do
      expect(helper.pr_section_present?('<hr><table><tr><td></td></tr></table>')).to be(false)
    end

    it 'is false for a fragment that is only an entity' do
      expect(helper.pr_section_present?('&nbsp;')).to be(false)
    end

    it 'is false for the BEGIN/END comments Rails adds around a render in development' do
      expect(helper.pr_section_present?('<!-- BEGIN app/views/x.erb --><!-- END -->')).to be(false)
    end

    it 'is true once there is real text' do
      expect(helper.pr_section_present?('<p>A context statement.</p>')).to be(true)
    end
  end

  describe '#pr_show_panes' do
    let(:presenter) do
      double('presenter', authorized_file_set_ids: [], authorized_child_work_ids: [],
                          model_name: double(param_key: 'generic_work_resource'))
    end

    before { allow(helper).to receive(:pr_context_html).and_return('') }

    it 'always offers metadata, and nothing else when the work is bare' do
      expect(helper.pr_show_panes(presenter).map(&:first)).to eq([:metadata])
    end

    it 'adds context only when the featured content has text' do
      allow(helper).to receive(:pr_context_html).and_return('<p>Statement</p>')

      expect(helper.pr_show_panes(presenter).map(&:first)).to eq(%i[context metadata])
    end

    it 'adds items and files with their counts, in display order' do
      allow(presenter).to receive_messages(authorized_file_set_ids: %w[f1],
                                           authorized_child_work_ids: %w[w1 w2 w3])

      expect(helper.pr_show_panes(presenter)).to eq(
        [[:metadata, 'Additional information'],
         [:items, 'Items (3)'],
         [:files, 'Files (1)']]
      )
    end
  end

  it 'pages at twenty, above the Hyrax default of ten, so a work is not split mid-sequence' do
    expect(PracticeResearchHelper::DEFAULT_ROWS).to eq(20)
  end

  describe 'member pane pagination' do
    let(:ids) { (1..12).map { |n| "work-#{n}" } }
    let(:presenter) { double('presenter', authorized_file_set_ids: %w[file-1], authorized_child_work_ids: ids) }

    before { stub_const("#{described_class}::DEFAULT_ROWS", 10) }

    it 'returns one page but counts them all' do
      page = helper.pr_child_work_ids(presenter)

      expect(page.size).to eq(10)
      expect(page.total_count).to eq(12)
      expect(page.total_pages).to eq(2)
    end

    it 'reads its own page param, so the two panes move independently' do
      helper.params[:items_page] = '2'

      expect(helper.pr_child_work_ids(presenter).to_a).to eq(%w[work-11 work-12])
      expect(helper.pr_file_set_ids(presenter).to_a).to eq(%w[file-1])
    end

    it 'keeps deposit order across the page boundary' do
      page_one = helper.pr_child_work_ids(presenter).to_a

      helper.instance_variable_set(:@theme_child_work_ids, nil)
      helper.params[:items_page] = '2'

      expect(page_one + helper.pr_child_work_ids(presenter).to_a).to eq(ids)
    end

    it 'clamps an out-of-range page to the last one, as Hyrax does' do
      helper.params[:items_page] = '99'

      page = helper.pr_child_work_ids(presenter)

      expect(page.current_page).to eq(2)
      expect(page.to_a).to eq(%w[work-11 work-12])
    end

    it 'honours rows, so both panes page at the same size' do
      helper.params[:rows] = '2'

      expect(helper.pr_child_work_ids(presenter).total_pages).to eq(6)
      expect(helper.pr_file_set_ids(presenter).total_pages).to eq(1)
    end

    it 'asks the presenter for the page of presenters, not the whole list' do
      expect(presenter).to receive(:member_presenters) { |page| expect(page.size).to eq(10) }

      helper.pr_child_works(presenter)
    end

    it 'falls back to the default rows for a value with no digits' do
      helper.params[:rows] = 'abc'

      expect(helper.pr_child_work_ids(presenter).limit_value).to eq(10)
    end

    it 'clamps rows away from zero' do
      helper.params[:rows] = '0'

      expect(helper.pr_child_work_ids(presenter).limit_value).to eq(1)
    end

    it 'clamps rows to the ceiling' do
      helper.params[:rows] = '999999'

      expect(helper.pr_child_work_ids(presenter).limit_value).to eq(PracticeResearchHelper::MAX_ROWS)
    end

    it 'clamps a page number too large for Kaminari to the last page' do
      helper.params[:items_page] = '99999999999999999999'

      expect(helper.pr_child_work_ids(presenter).current_page).to eq(2)
    end

    it 'reads the digits out of an array param instead of raising' do
      helper.params[:rows] = ['5']

      expect(helper.pr_child_work_ids(presenter).limit_value).to eq(5)
    end
  end

  describe '#theme_active_pane' do
    let(:presenter) do
      double('presenter', authorized_file_set_ids: Array.new(7) { |n| "f#{n}" },
                          authorized_child_work_ids: Array.new(12) { |n| "w#{n}" },
                          model_name: double(param_key: 'generic_work_resource'))
    end

    before { allow(helper).to receive(:pr_context_html).and_return('<p>Statement</p>') }

    it 'is the first pane with no page param' do
      expect(helper.theme_active_pane(helper.pr_show_panes(presenter))).to eq(:context)
    end

    it 'opens the pane the pager link names' do
      helper.params[:pane] = 'items'

      expect(helper.theme_active_pane(helper.pr_show_panes(presenter))).to eq(:items)
    end

    it 'opens it on page one too, where Kaminari drops the page param' do
      helper.params[:pane] = 'files'

      expect(helper.pr_file_set_ids(presenter).current_page).to eq(1)
      expect(helper.theme_active_pane(helper.pr_show_panes(presenter))).to eq(:files)
    end

    it 'ignores a pane that is not being shown' do
      allow(presenter).to receive_messages(authorized_file_set_ids: [],
                                           authorized_child_work_ids: Array.new(12) { |n| "w#{n}" })
      helper.params[:pane] = 'files'

      expect(helper.theme_active_pane(helper.pr_show_panes(presenter))).to eq(:context)
    end

    it 'ignores a pane that does not exist' do
      helper.params[:pane] = 'nonsense'

      expect(helper.theme_active_pane(helper.pr_show_panes(presenter))).to eq(:context)
    end

    it 'ignores an array pane instead of raising on it' do
      helper.params[:pane] = ['items']

      expect(helper.theme_active_pane(helper.pr_show_panes(presenter))).to eq(:context)
    end
  end

  describe '#pr_metadata_rows' do
    let(:presenter) { double('presenter') }
    let(:fields) { (1..11).map { |n| [:"field_#{n}", {}] } }

    before { allow(helper).to receive(:pr_metadata_fields).and_return(fields) }

    it 'puts the first eight above the disclosure and the rest behind it' do
      shown, rest = helper.pr_metadata_rows(presenter)

      expect(shown.size).to eq(8)
      expect(rest.map(&:first)).to eq(%i[field_9 field_10 field_11])
    end

    it 'leaves the disclosure group empty when there is nothing to hide' do
      allow(helper).to receive(:pr_metadata_fields).and_return(fields.first(3))

      expect(helper.pr_metadata_rows(presenter).last).to be_empty
    end

    it 'takes an explicit visible count' do
      shown, = helper.pr_metadata_rows(presenter, visible: 2)

      expect(shown.map(&:first)).to eq(%i[field_1 field_2])
    end
  end

  describe '#pr_metadata_fields' do
    let(:presenter) { double('presenter', editor?: false, title: ['A title'], empty_field: []) }

    before do
      allow(helper).to receive(:view_options_for).and_return(
        title: {}, empty_field: {}, carded: {}, admin_note: {}
      )
      allow(helper).to receive(:compound_card_field?) { |_p, field| field == :carded }
      allow(helper).to receive(:conform_options) { |_f, opts| opts }
      allow(helper).to receive(:conform_field) { |field, _opts| field }
      allow(helper).to receive(:field_visible?).and_return(true)
    end

    it 'keeps only fields that will actually render a value' do
      expect(helper.pr_metadata_fields(presenter).map(&:first)).to eq([:title])
    end
  end

  describe '#pr_card_fields' do
    let(:presenter) { double('presenter', identifiers: [{ 'value' => 'doi:10.1/x' }], blank: []) }

    before do
      allow(helper).to receive(:compound_schema_for)
        .and_return(double('schema', card_compound_names: %i[participants relationships identifiers blank]))
    end

    it 'drops the two the sidebar renders by hand, and any field with no value' do
      expect(helper.pr_card_fields(presenter)).to eq([:identifiers])
    end
  end
end
