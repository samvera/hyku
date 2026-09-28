# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReferenceHelper, type: :helper do
  describe '#ref_creators' do
    it 'joins the names with semicolons, since a name may itself hold a comma' do
      object = double('object', creator: ['Wolcott, Marion Post', 'Hine, Lewis Wickes'])

      expect(helper.ref_creators(object)).to eq('Wolcott, Marion Post; Hine, Lewis Wickes')
    end

    it 'stops at three and says so, rather than running the byline off the card' do
      object = double('object', creator: %w[One Two Three Four])

      expect(helper.ref_creators(object)).to eq('One; Two; Three; and others')
    end

    it 'takes a different limit' do
      object = double('object', creator: %w[One Two Three])

      expect(helper.ref_creators(object, limit: 2)).to eq('One; Two; and others')
    end

    it 'drops blank entries rather than emitting a stray semicolon' do
      object = double('object', creator: ['Hine, Lewis Wickes', '', nil])

      expect(helper.ref_creators(object)).to eq('Hine, Lewis Wickes')
    end

    it 'is nil when there is no creator at all, so the byline is not rendered' do
      expect(helper.ref_creators(double('object', creator: []))).to be_nil
      expect(helper.ref_creators(double('object', creator: nil))).to be_nil
    end
  end

  describe '#ref_provenance' do
    def document(attributes = {})
      SolrDocument.new({ 'embargo_release_date_dtsi' => nil }.merge(attributes))
    end

    it 'reads publisher, date and collection in that order' do
      line = helper.ref_provenance(
        document('publisher_tesim' => ['Coast Survey Office'],
                 'date_created_tesim' => ['1912'],
                 'member_of_collections_ssim' => ['Coastal Surveys'])
      )

      expect(line).to eq('Coast Survey Office · 1912 · Coastal Surveys')
    end

    it 'closes the gaps left by the parts a record does not have' do
      expect(helper.ref_provenance(document('date_created_tesim' => ['1912']))).to eq('1912')
    end

    it 'is nil when the record has none of them' do
      expect(helper.ref_provenance(document)).to be_nil
    end

    it 'notes an embargo, which is the one part a visitor cannot infer from the record' do
      line = helper.ref_provenance(
        document('date_created_tesim' => ['1912'], 'embargo_release_date_dtsi' => '2030-01-01T00:00:00Z')
      )

      expect(line).to eq('1912 · under embargo')
    end
  end

  describe '#ref_rights_statement' do
    it 'labels a rights statement URI' do
      document = SolrDocument.new('rights_statement_tesim' => ['http://rightsstatements.org/vocab/NoC-US/1.0/'])

      expect(helper.ref_rights_statement(document)).to eq('No Copyright - United States')
    end

    it 'is nil with no rights statement, so the badge is not rendered' do
      expect(helper.ref_rights_statement(SolrDocument.new)).to be_nil
    end
  end
end
