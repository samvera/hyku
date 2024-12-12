# frozen_string_literal: true

RSpec.describe ApplicationHelper, type: :helper do
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
