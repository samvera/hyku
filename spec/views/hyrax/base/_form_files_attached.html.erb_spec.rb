# frozen_string_literal: true

RSpec.describe 'hyrax/base/_form_files_attached.html.erb', type: :view do
  let(:work_form) { double('WorkForm') }
  let(:form) { double('FormBuilder', object: work_form) }

  let(:document) { double('SolrDocument', id: 'fs-1', alt_text_for_view: 'A scanned cover') }

  let(:file_set) do
    double('FileSetPresenter',
           id: 'fs-1',
           solr_document: document,
           link_name: 'cover.jpg')
  end

  def render_list
    render 'hyrax/base/form_files_attached', f: form
  end

  context 'when the work has attached file sets' do
    before { allow(view).to receive(:attached_file_set_presenters).with(work_form).and_return([file_set]) }

    it 'names the attached file' do
      render_list

      expect(rendered).to have_selector('.attached-files .name', text: 'cover.jpg')
    end

    it 'renders the thumbnail derivative rather than the full-size file' do
      render_list

      expect(rendered).to have_selector("img[src='/downloads/fs-1?file=thumbnail'][alt='A scanned cover']")
    end

    it 'bounds the thumbnail inline, so it stays small without a stylesheet' do
      render_list

      expect(rendered).to have_selector("img.attached-file-thumbnail[style*='max-width: 64px']")
      expect(rendered).to have_selector("img.attached-file-thumbnail[style*='max-height: 64px']")
    end

    it 'tells the depositor where files can be edited or removed' do
      render_list

      expect(rendered).to have_text('Current files can be edited or removed on their individual show pages.')
    end

    it 'introduces the list before the files, not after' do
      render_list

      caption = rendered.index(I18n.t('hyrax.base.form_files_attached.caption'))
      first_file = rendered.index('cover.jpg')

      expect(caption).to be < first_file
    end

    it 'sets the list apart from the uploader in its own card' do
      render_list

      expect(rendered).to have_selector('.card.attached-files-card .card-header .attached-files-caption')
      expect(rendered).to have_selector('.card.attached-files-card .card-body table.attached-files')
    end

    it 'renders the new-files heading hidden, for the uploader JS to reveal' do
      render_list

      expect(rendered).to have_selector('[data-behavior="new-files-heading"][hidden]', visible: :all)
    end

    it 'does not render column headings' do
      render_list

      expect(rendered).not_to have_selector('.attached-files th')
    end

    it 'is entirely read-only: no inputs, and no links or buttons off the form' do
      render_list

      expect(rendered).not_to have_selector('.attached-files input')
      expect(rendered).not_to have_selector('.attached-files select')
      expect(rendered).not_to have_selector('.attached-files a')
      expect(rendered).not_to have_selector('.attached-files button')
    end
  end

  context 'when the work has no attached file sets' do
    before { allow(view).to receive(:attached_file_set_presenters).with(work_form).and_return([]) }

    it 'renders nothing at all' do
      render_list

      expect(rendered.strip).to be_empty
    end
  end
end
