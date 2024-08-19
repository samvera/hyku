# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Etd`
require 'rails_helper'
require 'order_already/spec_helper'

RSpec.describe Etd do
  include_examples('includes OrderMetadataValues')

  describe '#iiif_print_config#pdf_splitter_service' do
    subject { described_class.new.iiif_print_config.pdf_splitter_service }

    it { is_expected.to eq(IiifPrint::TenantConfig::PdfSplitter) }
  end

  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq EtdIndexer }
  end

  it { is_expected.to have_already_ordered_attributes(*described_class.multi_valued_properties_for_ordering) }

  describe 'metadata properties' do
    it { is_expected.to have_property(:bulkrax_identifier).with_predicate("https://hykucommons.org/terms/bulkrax_identifier") }

    context ':title' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.title = ['Lorem']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/terms\/title/)
        expect(etd.title.first).to eq('Lorem')
      end
    end

    context ':creator' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.creator = ['Ipsum']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/elements\/1.1\/creator/)
        expect(etd.creator.first).to eq('Ipsum')
      end
    end

    context ':keyword' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.keyword = ['Dolor']
        expect(etd.resource.dump(:ttl)).to match(/schema.org\/keywords/)
        expect(etd.keyword.first).to eq('Dolor')
      end
    end

    context ':rights_statement' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.rights_statement = ['http://rightsstatements.org/vocab/CNE/1.0/']
        expect(etd.resource.dump(:ttl)).to match(/www.europeana.eu\/schemas\/edm\/rights/)
        expect(etd.rights_statement.first).to match(/^http:\/\/rightsstatements.org/)
      end
    end

    context ':contributor' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.contributor = ['Sit']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/elements\/1.1\/contributor/)
        expect(etd.contributor.first).to eq('Sit')
      end
    end

    context ':description' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.description = ['Amet']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/elements\/1.1\/description/)
        expect(etd.description.first).to eq('Amet')
      end
    end

    context ':license' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.license = ['https://creativecommons.org/licenses/by/4.0/']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/terms\/license/)
        expect(etd.license.first).to match(/^https:\/\/creativecommons.org/)
      end
    end

    context ':publisher' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.publisher = ['Kyle']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/elements\/1.1\/publisher/)
        expect(etd.publisher.first).to eq('Kyle')
      end
    end

    context ':subject' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.subject = ['Electronics']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/elements\/1.1\/subject/)
        expect(etd.subject.first).to eq('Electronics')
      end
    end

    context ':language' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.language = ['English']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/elements\/1.1\/language/)
        expect(etd.language.first).to eq('English')
      end
    end

    context ':identifier' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.identifier = ['ID123']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/terms\/identifier/)
        expect(etd.identifier.first).to eq('ID123')
      end
    end

    context ':source' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.source = ['asdf']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/terms\/source/)
        expect(etd.source.first).to eq('asdf')
      end
    end

    context ':resource_type' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.resource_type = ['Dissertation']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/terms\/type/)
        expect(etd.resource_type.first).to eq('Dissertation')
      end
    end

    context ':format' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.format = ['gg=G']
        expect(etd.resource.dump(:ttl)).to match(/purl.org\/dc\/terms\/format/)
        expect(etd.format.first).to eq('gg=G')
      end
    end

    context ':degree_name' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.degree_name = ['Com Sci']
        expect(etd.resource.dump(:ttl)).to match(/hykucommons.org\/terms\/degree_name/)
        expect(etd.degree_name.first).to eq('Com Sci')
      end
    end

    context ':degree_level' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.degree_level = ['High']
        expect(etd.resource.dump(:ttl)).to match(/hykucommons.org\/terms\/degree_level/)
        expect(etd.degree_level.first).to eq('High')
      end
    end

    context ':degree_discipline' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.degree_discipline = ['Computers']
        expect(etd.resource.dump(:ttl)).to match(/hykucommons.org\/terms\/degree_discipline/)
        expect(etd.degree_discipline.first).to eq('Computers')
      end
    end

    context ':degree_grantor' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.degree_grantor = ['UCSD']
        expect(etd.resource.dump(:ttl)).to match(/hykucommons.org\/terms\/degree_grantor/)
        expect(etd.degree_grantor.first).to eq('UCSD')
      end
    end

    context ':advisor' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.advisor = ['Yoda']
        expect(etd.resource.dump(:ttl)).to match(/hykucommons.org\/terms\/advisor/)
        expect(etd.advisor.first).to eq('Yoda')
      end
    end

    context ':committee_member' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.committee_member = ['Qui Gon Jinn']
        expect(etd.resource.dump(:ttl)).to match(/hykucommons.org\/terms\/committee_member/)
        expect(etd.committee_member.first).to eq('Qui Gon Jinn')
      end
    end

    context ':department' do
      let(:etd) { FactoryBot.build(:etd) }
      it 'is a property' do
        etd.department = ['Tech']
        expect(etd.resource.dump(:ttl)).to match(/hykucommons.org\/terms\/department/)
        expect(etd.department.first).to eq('Tech')
      end
    end
  end
end
