# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PracticeResearchHomeHelper, type: :helper do
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
end
