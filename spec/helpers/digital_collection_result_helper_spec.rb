# frozen_string_literal: true

RSpec.describe DigitalCollectionResultHelper, type: :helper do
  let(:document) do
    SolrDocument.new('id' => 'w1', 'has_model_ssim' => ['GenericWork'], 'title_tesim' => ['Ward'], 'creator_tesim' => ['Allen & Ginter'],
                     'date_created_tesim' => ['1887'], 'resource_type_tesim' => ['Image'], 'description_tesim' => ['One print.'],
                     'member_of_collection_ids_ssim' => ['c1'], 'member_of_collections_ssim' => ['Baseball Cards'])
  end

  def rows
    helper.dc_result_fields(document).to_h { |key, row| [key, Capybara.string(row)] }
  end

  context 'with flexible metadata' do
    let(:profile_fields) do
      { 'title_tesim' => ['Title', 'Ward'], 'keyword_tesim' => ['Keyword', '<a href="/catalog?q=cards">cards</a>'.html_safe],
        'creator_tesim' => ['Maker', 'Allen & Ginter'], 'date_created_tesim' => ['Date Created', '1887'], 'abstract_tesim' => ['Abstract', ''] }
    end

    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      presenter = instance_double(Blacklight::DocumentPresenter)
      allow(presenter).to receive(:fields_to_render) do
        profile_fields.map { |name, (_label, value)| [name, Blacklight::Configuration::IndexField.new(key: name), instance_double(Blacklight::FieldPresenter, render: value)] }
      end
      allow(helper).to receive(:document_presenter).and_return(presenter)
      allow(helper).to receive(:index_field_label) { |_doc, name| profile_fields[name].first }
      allow(helper).to receive(:markdown) { |value| value }
    end

    it "shows the profile's search result fields in its order with its labels, leaving out the title and empty values" do
      expect(rows.keys).to eq(%i[keyword creator date_created part_of])
      expect(rows[:creator]).to have_css('dt', text: 'Maker')
      expect(rows[:keyword].find('a')['href']).to eq('/catalog?q=cards')
    end

    it 'adds the Part of link after the profile fields' do
      expect(rows[:part_of].find('a', text: 'Baseball Cards')['href']).to include('/collections/c1')
    end

    it 'leaves the creator off a card when the profile keeps it out of search results' do
      profile_fields.delete('creator_tesim')

      expect(helper.dc_card_meta(document)).to eq('1887')
    end
  end

  context 'without flexible metadata' do
    before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

    it "shows the theme's fields with plain values" do
      expect(rows.keys).to eq(%i[creator date part_of resource_type description])
      expect(rows[:creator]).to have_css('dt', text: 'Creator')
      expect(rows[:creator]).to have_no_css('a')
    end

    it 'puts the creator and date on a card' do
      expect(helper.dc_card_meta(document)).to eq('Allen & Ginter · 1887')
    end
  end
end
