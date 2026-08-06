# frozen_string_literal: true

RSpec.describe 'hyrax/base/_download_pdf.html.erb', type: :view do
  # Stands in for a file set presenter: the partial only needs id, pdf? and to_param.
  let(:file_set_class) do
    Struct.new(:id, :pdf) do
      alias_method :pdf?, :pdf
      def to_param
        id
      end
    end
  end
  let(:image) { file_set_class.new('img-1', false) }
  let(:pdf) { file_set_class.new('pdf-1', true) }
  let(:file_set_presenters) { [image, pdf] }
  let(:representative_id) { image.id }
  let(:presenter) do
    double('WorkShowPresenter', file_set_presenters: file_set_presenters, representative_id: representative_id)
  end
  let(:downloadable_ids) { file_set_presenters.map(&:id) }

  before do
    allow(view).to receive(:can?) { |_action, id| downloadable_ids.include?(id) }
  end

  def render_button
    # file_set_id is what the show pages pass; the partial no longer uses it.
    render 'hyrax/base/download_pdf', presenter: presenter, file_set_id: image.id
  end

  context 'when the representative is not the PDF' do
    it 'points the button at the PDF file set' do
      render_button

      expect(rendered).to have_selector("#file_download[data-label='pdf-1']", text: I18n.t('hyrax.base.download_pdf'), visible: :all)
      expect(rendered).to have_selector("#file_download[data-path*='pdf-1']", visible: :all)
      expect(rendered).not_to have_selector("#file_download[data-path*='img-1']", visible: :all)
    end
  end

  context 'when the representative is one of several PDFs' do
    let(:other_pdf) { file_set_class.new('pdf-2', true) }
    let(:file_set_presenters) { [pdf, other_pdf] }
    let(:representative_id) { other_pdf.id }

    it 'points the button at the representative' do
      render_button

      expect(rendered).to have_selector("#file_download[data-path*='pdf-2']", visible: :all)
    end
  end

  context 'when the user can download the representative but not the PDF' do
    let(:downloadable_ids) { [image.id] }

    it 'renders nothing' do
      render_button

      expect(rendered).not_to have_selector('#file_download', visible: :all)
    end
  end

  context 'when the user can download a later PDF but not the first' do
    let(:other_pdf) { file_set_class.new('pdf-2', true) }
    let(:file_set_presenters) { [pdf, other_pdf] }
    let(:downloadable_ids) { [other_pdf.id] }

    it 'points the button at the readable PDF' do
      render_button

      expect(rendered).to have_selector("#file_download[data-path*='pdf-2']", visible: :all)
    end
  end

  context 'when there is no PDF' do
    let(:file_set_presenters) { [image] }

    it 'renders nothing' do
      render_button

      expect(rendered).not_to have_selector('#file_download', visible: :all)
    end
  end
end
