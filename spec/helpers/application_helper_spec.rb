# frozen_string_literal: true

RSpec.describe ApplicationHelper do
  describe "#markdown" do
    let(:header) { '# header' }
    let(:bold) { '*bold*' }

    it 'renders markdown into html' do
      expect(helper.markdown(header)).to eq("<h1>header</h1>\n")
      expect(helper.markdown(bold)).to eq("<p><em>bold</em></p>\n")
    end
  end

  describe '#local_for' do
    context 'when term is missing' do
      subject { helper.locale_for(type: 'labels', record_class: "account", term: :very_much_missing) }
      it { is_expected.to be_a(String) }
    end
  end
end
