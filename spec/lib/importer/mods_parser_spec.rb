require 'importer'

RSpec.describe Importer::ModsParser do
  let(:parser) { described_class.new(file) }
  let(:attributes) { parser.attributes }

  describe 'Determine which kind of record it is:' do
    describe 'for a collection:' do
      let(:file) { 'spec/fixtures/mods/shpc/kx532cb7981.mods' }

      it 'knows it is a Collection' do
        expect(parser.collection?).to eq true
        expect(parser.image?).to eq false
        expect(parser.model).to eq Collection
      end
    end

    describe 'for an image:' do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'knows it is an Image' do
        expect(parser.image?).to eq true
        expect(parser.collection?).to eq false
        expect(parser.model).to eq "Image"
      end
    end
  end

  describe '#attributes for an Image record' do
    let(:ns_decl) { "xmlns='#{Mods::MODS_NS}'" }
    let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

    it 'finds metadata for the image' do
      expect(attributes[:description]).to eq []
      expect(attributes[:location]).to eq []
      expect(attributes[:form_of_work]).to eq []
      expect(attributes[:extent]).to eq []
      expect(attributes[:accession_number]).to eq ["8735.2", "15097"]
      expect(attributes[:sub_location]).to eq []
      expect(attributes[:citation]).to eq []
      acquisition_note = attributes[:notes_attributes].first
      expect(acquisition_note[:note_type]).to be nil
      expect(acquisition_note[:value]).to start_with '"Left to right'
      expect(attributes[:description_standard]).to eq []
      expect(attributes[:series_name]).to eq []
      expect(attributes[:restrictions]).to eq []
      expect(attributes[:institution]).to eq [
        "Stanford University. Libraries. Dept. of Special Collections & University Archives."
      ]
    end

    context 'with a file that has a general (untyped) note' do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'imports notes' do
        expect(attributes[:notes_attributes].first[:value]).to start_with(
          "\"Left to right: Anna Maria Lathrop"
        )
      end
    end

    context 'with a file that has a publisher', skip: "need a record with originInfo" do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'imports publisher' do
        expect(attributes[:publisher]).to eq ['[Cross & Dimmit Pictures]']
      end
    end

    context 'with a file that has a photographer', skip: "we're not doing relators beyond contributor" do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'imports photographer' do
        expect(attributes[:photographer]).to eq ['http://id.loc.gov/authorities/names/n97003180']
      end
    end

    it 'imports contributor' do
      expect(attributes[:contributor]).to eq [{ name: ["Muybridge"], type: "corporate" }]
    end

    it 'imports language' do
      # I think this record should be:
      # expect(attributes[:language]).to eq ['http://id.loc.gov/vocabulary/iso639-2/zxx']
      expect(attributes[:language]).to eq ['en']
    end

    it 'imports resource_type' do
      expect(attributes[:resource_type]).to eq ['still image']
    end

    it 'imports digital origin', skip: "Need a record with digital origin" do
      expect(attributes[:digital_origin]).to eq ['digitized other analog']
    end

    context 'with a file that has coordinates', skip: 'Need metadata with geo data' do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'imports coordinates' do
        expect(attributes[:latitude]).to eq ['34.442982']
        expect(attributes[:longitude]).to eq ['-119.657362']
      end
    end

    it 'finds metadata for the collection' do
      # This only worked because I downloaded the mods from purl
      expect(attributes[:collection][:identifier]).to eq ['http://purl.stanford.edu/kx532cb7981']
      expect(attributes[:collection][:title]).to eq ['Stanford historical photograph collection, 1887-circa 1996']
    end

    context 'with a range of dateCreated', skip: "no dates on this record" do
      it 'imports created' do
        expect(attributes[:created_attributes]).to eq [
          { start: ['1910'],
            finish: ['1919'],
            label: ['circa 1910s'],
            start_qualifier: ['approximate'],
            finish_qualifier: ['approximate'] }
        ]
      end
    end

    context 'without date_created' do
      let(:parser) { described_class.new(nil) }
      let(:xml) do
        "<mods #{ns_decl}><originInfo><dateValid encoding=\"w3cdtf\">1989-12-01</dateValid></originInfo></mods>"
      end

      before { allow(parser).to receive(:mods).and_return(Mods::Record.new.from_str(xml)) }

      it "doesn't return a set of empty date attributes (which would cause an empty TimeSpan to be created)" do
        expect(attributes[:created_attributes]).to eq []
      end
    end

    context 'with a file that has a range of dateIssued', skip: "no dates on this record" do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'imports issued' do
        expect(attributes[:issued_attributes]).to eq [
          { start: ['1900'],
            finish: ['1959'],
            label: ['circa 1900s-1950s'],
            start_qualifier: ['approximate'],
            finish_qualifier: ['approximate'] }
        ]
      end
    end

    context 'with a file that has a single dateIssued', skip: "no dates on this record" do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'imports issued' do
        expect(attributes[:issued_attributes]).to eq [
          { start: ['1925'],
            finish: [],
            label: [],
            start_qualifier: [],
            finish_qualifier: [] }
        ]
      end
    end

    context 'with date_copyrighted', skip: "no dates on this record" do
      let(:parser) { described_class.new(nil) }
      let(:xml) do
        "<mods #{ns_decl}><originInfo><copyrightDate encoding=\"w3cdtf\">1985-12-01</copyrightDate></originInfo></mods>"
      end

      before { allow(parser).to receive(:mods).and_return(Mods::Record.new.from_str(xml)) }

      it 'imports date_copyrighted' do
        expect(attributes[:date_copyrighted_attributes]).to eq [
          { start: ['1985-12-01'],
            finish: [],
            label: [],
            start_qualifier: [],
            finish_qualifier: [] }
        ]
      end
    end

    context 'with dateValid' do
      let(:parser) { described_class.new(nil) }
      let(:xml) do
        "<mods #{ns_decl}><originInfo><dateValid encoding=\"w3cdtf\">1989-12-01</dateValid></originInfo></mods>"
      end

      before { allow(parser).to receive(:mods).and_return(Mods::Record.new.from_str(xml)) }

      it 'imports date_valid' do
        expect(attributes[:date_valid_attributes]).to eq [
          { start: ['1989-12-01'],
            finish: [],
            label: [],
            start_qualifier: [],
            finish_qualifier: [] }
        ]
      end
    end

    context 'with a file that has an alternative title', skip: "Need a record with alt title" do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'distinguishes between title and alternative title' do
        expect(attributes[:title]).to eq ['Stanford residences -- Sacramento -- Muybridge']
        expect(attributes[:alternative]).to eq ['An alternative']
      end
    end

    context 'with a file that has placeTerm', skip: 'file has no originInfo' do
      let(:file) { 'spec/fixtures/mods/shpc/druid_xv169dn4538.mods' }

      it 'reads the place' do
        expect(attributes[:place_of_publication]). to eq ['Santa Barbara, California']
      end
    end
  end

  describe '#attributes for a Collection record' do
    let(:file) { 'spec/fixtures/mods/shpc/kx532cb7981.mods' }

    it 'finds the metadata' do
      expect(attributes[:title]).to eq ['Stanford historical photograph collection, 1887-circa 1996 (inclusive)']
      expect(attributes[:creator]).to be_nil
      expect(attributes[:contributor]).to eq [{ name: ['Stanford University', 'Archives.'], type: 'corporate' }]
      expect(attributes[:description].first).to start_with 'The Stanford historical photograph collection'
      expect(attributes[:extent]).to eq ['40 linear feet']
      expect(attributes[:language]).to eq ['eng']
      expect(attributes[:resource_type]).to eq ['still image']
      expect(attributes[:institution]).to eq [
        'Dept. of Special Collections & University Archives Stanford Univeristy Libraries'
      ]
    end
  end
end
