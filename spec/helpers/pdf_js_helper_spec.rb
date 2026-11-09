# frozen_string_literal: true

RSpec.describe PdfJsHelper, type: :helper do
  describe '#pdf_js_url' do
    it 'returns the viewer URL without a fragment when there is no search query' do
      allow(helper).to receive(:params).and_return({})
      expect(helper.pdf_js_url('/downloads/abc')).to eq '/pdf.js/viewer.html?file=/downloads/abc'
    end

    it 'appends a search fragment when a query param is present' do
      allow(helper).to receive(:params).and_return(q: 'capillary')
      expect(helper.pdf_js_url('/downloads/abc')).to eq '/pdf.js/viewer.html?file=/downloads/abc#search=capillary&phrase=true'
    end

    it 'returns the viewer URL without a fragment when the search query is blank' do
      allow(helper).to receive(:params).and_return(q: '')
      expect(helper.pdf_js_url('/downloads/abc')).to eq '/pdf.js/viewer.html?file=/downloads/abc'
    end

    it 'URL-encodes special characters in the search query' do
      allow(helper).to receive(:params).and_return(q: 'arts & crafts')
      url = helper.pdf_js_url('/downloads/abc')
      expect(url).to include('#search=arts%20%26%20crafts&phrase=true')
    end
  end

  describe '#pdf_file_set_presenter' do
    let(:file_set_class) { Struct.new(:id, :pdf) { alias_method :pdf?, :pdf } }
    let(:image) { file_set_class.new('img-1', false) }
    let(:pdf) { file_set_class.new('pdf-1', true) }
    let(:other_pdf) { file_set_class.new('pdf-2', true) }
    let(:presenter) do
      double('WorkShowPresenter', file_set_presenters: file_set_presenters, representative_id: representative_id)
    end

    context 'when the representative is not a PDF' do
      let(:file_set_presenters) { [image, pdf] }
      let(:representative_id) { image.id }

      it 'returns the first PDF rather than the representative' do
        expect(helper.pdf_file_set_presenter(presenter)).to eq pdf
      end
    end

    context 'when the representative is a PDF' do
      let(:file_set_presenters) { [pdf, other_pdf] }
      let(:representative_id) { other_pdf.id }

      it 'returns the representative' do
        expect(helper.pdf_file_set_presenter(presenter)).to eq other_pdf
      end
    end

    context 'when there is no PDF' do
      let(:file_set_presenters) { [image] }
      let(:representative_id) { image.id }

      it 'returns nil' do
        expect(helper.pdf_file_set_presenter(presenter)).to be_nil
      end
    end

    context 'with downloadable: true' do
      let(:file_set_presenters) { [pdf, other_pdf] }
      let(:representative_id) { pdf.id }

      before do
        allow(helper).to receive(:can?) { |_action, id| id == other_pdf.id }
      end

      it 'skips PDFs the user cannot download, including the representative' do
        expect(helper.pdf_file_set_presenter(presenter, downloadable: true)).to eq other_pdf
      end

      it 'returns nil when no PDF is downloadable' do
        allow(helper).to receive(:can?).and_return(false)

        expect(helper.pdf_file_set_presenter(presenter, downloadable: true)).to be_nil
      end
    end
  end
end
