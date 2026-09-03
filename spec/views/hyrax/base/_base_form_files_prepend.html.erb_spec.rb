# frozen_string_literal: true

RSpec.describe 'hyrax/base/_base_form_files_prepend.html.erb', type: :view do
  let(:form) { double('FormBuilder', object: double('WorkForm')) }

  def render_prepend
    render 'hyrax/base/base_form_files_prepend', f: form
  end

  before do
    # Both concerns of this partial are stubbed at their boundary; each has its
    # own spec. What matters here is that they coexist, in the right order.
    stub_template 'hyrax/base/_show_pdf_viewer.html.erb' => '<div id="pdf-viewer-checkbox"></div>'
    stub_template 'hyrax/base/_show_pdf_download_button.erb' => '<div id="pdf-download-checkbox"></div>'
    stub_template 'hyrax/base/_form_files_attached.html.erb' => '<div id="attached-files"></div>'
  end

  context 'when the work has a PDF, so the viewer checkboxes render' do
    before { allow(view).to receive(:render_show_pdf_behavior_checkbox?).and_return(true) }

    it 'renders both the PDF controls and the attached-files list' do
      render_prepend

      expect(rendered).to have_selector('#pdf-viewer-checkbox')
      expect(rendered).to have_selector('#pdf-download-checkbox')
      expect(rendered).to have_selector('#attached-files')
    end

    it 'keeps the PDF controls above the attached-files list' do
      render_prepend

      expect(rendered.index('pdf-viewer-checkbox')).to be < rendered.index('attached-files')
      expect(rendered.index('pdf-download-checkbox')).to be < rendered.index('attached-files')
    end
  end

  context 'when the work has no PDF' do
    before { allow(view).to receive(:render_show_pdf_behavior_checkbox?).and_return(false) }

    it 'omits the PDF controls but still lists the attached files' do
      render_prepend

      expect(rendered).not_to have_selector('#pdf-viewer-checkbox')
      expect(rendered).not_to have_selector('#pdf-download-checkbox')
      expect(rendered).to have_selector('#attached-files')
    end
  end
end
