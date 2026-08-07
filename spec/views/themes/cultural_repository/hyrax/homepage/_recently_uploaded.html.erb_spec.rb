# frozen_string_literal: true

RSpec.describe 'themes/cultural_repository/hyrax/homepage/_recently_uploaded.html.erb', type: :view do
  # This partial is rendered by its explicit path from _recent_works_section, so
  # lazy i18n lookup resolves under themes.cultural_repository.*, where no keys
  # exist. It must not leak a missing-translation artifact into the page.
  context 'with no recent documents' do
    before do
      render partial: 'themes/cultural_repository/hyrax/homepage/recently_uploaded',
             locals: { recent_documents: [] }
    end

    it 'renders the standard no-public-works message' do
      expect(rendered).to include(t('hyrax.homepage.recently_uploaded.no_public'))
    end

    it 'does not render a literal false' do
      expect(rendered).not_to match(/>\s*false\s*</)
    end
  end
end
