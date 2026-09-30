# frozen_string_literal: true

RSpec.describe 'Full-text snippets in catalog search results', type: :feature, clean: true, js: false do
  let(:work_document) do
    {
      'has_model_ssim' => ['GenericWork'],
      id: SecureRandom.uuid,
      'title_tesim' => ['Ledger of the harbor master'],
      'admin_set_tesim' => ['Default Admin Set'],
      'suppressed_bsi' => false,
      'read_access_group_ssim' => ['public'],
      'edit_access_group_ssim' => ['admin'],
      'visibility_ssi' => 'open',
      'all_text_tsimv' => ['The schooner Marigold arrived with a cargo of quinquereme timber and salted cod.']
    }
  end

  before do
    solr = Blacklight.default_index.connection
    solr.add(work_document)
    solr.commit
  end

  context 'when the keyword only matches the full text of a file set' do
    let(:file_set_id) { SecureRandom.uuid }
    let(:work_document) do
      {
        'has_model_ssim' => ['GenericWork'],
        id: SecureRandom.uuid,
        'title_tesim' => ['Ship manifest'],
        'admin_set_tesim' => ['Default Admin Set'],
        'suppressed_bsi' => false,
        'read_access_group_ssim' => ['public'],
        'edit_access_group_ssim' => ['admin'],
        'visibility_ssi' => 'open',
        'member_ids_ssim' => [file_set_id]
      }
    end
    let(:file_set_document) do
      {
        'has_model_ssim' => ['FileSet'],
        id: file_set_id,
        'title_tesim' => ['manifest.pdf'],
        'read_access_group_ssim' => ['public'],
        'visibility_ssi' => 'open',
        'all_text_tsimv' => ['Forty barrels of quinquereme pitch.']
      }
    end

    before do
      solr = Blacklight.default_index.connection
      solr.add(file_set_document)
      solr.commit
    end

    it 'finds the parent work through the file set join' do
      visit '/catalog?q=quinquereme&search_field=all_fields'

      expect(page).to have_css('h3.search-result-title', text: 'Ship manifest')
    end
  end
end
