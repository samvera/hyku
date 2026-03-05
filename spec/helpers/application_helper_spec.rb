# frozen_string_literal: true

RSpec.describe ApplicationHelper, type: :helper do
  describe '#thumbnail_alt_text_for' do
    let(:document) { SolrDocument.new('thumbnail_alt_text_tesim' => thumbnail_alt_text, 'title_tesim' => ['My Work']) }

    context 'when the document has thumbnail_alt_text (real thumbnail)' do
      let(:thumbnail_alt_text) { ['Custom alt text'] }

      it 'returns alt_text_for_view from the document' do
        expect(helper.thumbnail_alt_text_for(document)).to eq(document.alt_text_for_view)
      end

      it 'does not check the content block' do
        expect(helper).not_to receive(:block_for)
        helper.thumbnail_alt_text_for(document)
      end
    end

    context 'when the document has no thumbnail_alt_text (default image showing)' do
      let(:thumbnail_alt_text) { [] }

      context 'when a content block is configured' do
        before { allow(helper).to receive(:block_for).with(name: 'default_work_image_text').and_return('Site default alt') }

        it 'returns the content block value' do
          expect(helper.thumbnail_alt_text_for(document)).to eq('Site default alt')
        end
      end

      context 'when no content block is configured' do
        before { allow(helper).to receive(:block_for).with(name: 'default_work_image_text').and_return(false) }

        it 'falls back to alt_text_for_view' do
          expect(helper.thumbnail_alt_text_for(document)).to eq(document.alt_text_for_view)
        end
      end

      context 'with a collection block_name' do
        before { allow(helper).to receive(:block_for).with(name: 'default_collection_image_text').and_return('Collection default') }

        it 'uses the provided block_name' do
          expect(helper.thumbnail_alt_text_for(document, block_name: 'default_collection_image_text')).to eq('Collection default')
        end
      end
    end
  end

  describe "#markdown" do
    let(:header) { '# header' }
    let(:bold) { '*bold*' }

    context 'when treat_some_user_inputs_as_markdown is true' do
      it 'renders markdown into html' do
        allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(true)

        expect(helper.markdown(header)).to eq("<h1>header</h1>\n")
        expect(helper.markdown(bold)).to eq("<p><em>bold</em></p>\n")
      end
    end

    context 'when treat_some_user_inputs_as_markdown is false' do
      it 'does not render markdown into html' do
        allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(false)

        expect(helper.markdown(header)).to eq('# header')
        expect(helper.markdown(bold)).to eq('*bold*')
      end
    end
  end

  describe '#local_for' do
    context 'when term is missing' do
      it 'returns nil' do
        expect(helper.locale_for(type: 'labels', record_class: "account", term: :very_much_missing)).to be_nil
      end
    end
  end
end
