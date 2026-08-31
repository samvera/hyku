# frozen_string_literal: true

RSpec.describe 'Requesting a work type the tenant does not offer', type: :request, singletenant: true, clean: true do
  let(:admin) { FactoryBot.create(:admin) }

  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    FactoryBot.create(:editors_group)
    FactoryBot.create(:depositors_group)

    login_as admin
  end

  context 'when the site does not enable the type' do
    before { Site.instance.update!(available_works: %w[Image]) }

    it 'refuses new with a message rather than building the form' do
      get new_hyrax_generic_work_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t('hyku.works.errors.work_type_not_offered'))
    end

    it 'refuses create rather than persisting a work' do
      expect do
        post hyrax_generic_works_path, params: { generic_work: { title: ['Should not be created'] } }
      end.not_to change { Hyrax.query_service.count_all_of_model(model: GenericWorkResource) }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t('hyku.works.errors.work_type_not_offered'))
    end
  end

  context 'when the site enables the type' do
    before { Site.instance.update!(available_works: %w[GenericWork Image]) }

    it 'allows new through' do
      get new_hyrax_generic_work_path

      expect(response).to have_http_status(:ok)
    end

    # A reload detaches to_rdf_representation, so the registry returns the class name.
    it 'allows new through when the registry falls back to the class name' do
      allow(Hyrax::ModelRegistry).to receive(:rdf_representations_from).and_return(['GenericWorkResource'])

      get new_hyrax_generic_work_path

      expect(response).to have_http_status(:ok)
    end
  end
end
