# frozen_string_literal: true

RSpec.describe 'Deposit wizard', type: :request, singletenant: true, clean: true do
  let(:admin) { FactoryBot.create(:admin) }

  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    login_as admin
  end

  describe 'GET /deposit_wizard' do
    context 'when the deposit_wizard feature is off' do
      before { allow(Flipflop).to receive(:deposit_wizard?).and_return(false) }

      it 'redirects to the dashboard with an alert and does not expose the wizard' do
        get deposit_wizard_path

        expect(response).to redirect_to(hyrax.my_works_path)
        expect(flash[:alert]).to eq(I18n.t('hyku.deposit_wizard.disabled'))
      end
    end

    context 'when the deposit_wizard feature is on' do
      before { allow(Flipflop).to receive(:deposit_wizard?).and_return(true) }

      it 'renders the start screen' do
        get deposit_wizard_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.heading'))
      end

      it 'renders the dashboard breadcrumb trail' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyrax.controls.home'))
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.button'))
      end
    end
  end

  describe 'GET /deposit_wizard/:step with an unknown step' do
    before { allow(Flipflop).to receive(:deposit_wizard?).and_return(true) }

    it 'falls back to the start screen' do
      get deposit_wizard_step_path(step: 'does_not_exist')

      expect(response).to redirect_to(deposit_wizard_path)
    end
  end

  describe 'navigation and type selection' do
    before do
      allow(Flipflop).to receive(:deposit_wizard?).and_return(true)
      Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    end

    # A work type the wizard offers (same list as the stock deposit chooser).
    let(:work_type) do
      Hyrax::QuickClassificationQuery.new(admin).authorized_models.first.to_s
    end

    # The param key is shared by the ActiveFedora model and its Valkyrie form.
    let(:param_key) { work_type.constantize.model_name.param_key }

    after { Hyku::DepositWizard.reset_config! }

    context 'with a flat config (no container)' do
      before { Hyku::DepositWizard.reset_config! }

      it 'renders a work-type chooser on the start screen' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.known_type.heading'))
      end

      it 'shows an empty-state message when no work types are available' do
        allow_any_instance_of(Hyrax::QuickClassificationQuery).to receive(:authorized_models).and_return([])

        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.no_work_types'))
      end

      it 'persists the chosen work type and advances to the files step' do
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'files'))
        expect(session[:deposit_wizard]['work_type']).to eq(work_type)
        expect(session[:deposit_wizard]['path']).to eq('standalone')
      end

      it 're-renders with an alert when the work type is not allowed' do
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: 'NotAWorkType' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.no_work_type'))
        expect(session[:deposit_wizard]['work_type']).to be_nil
      end
    end

    context 'with a container config' do
      before do
        Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new { |c| c.container_type = 'GenericWorkResource' }
      end

      it 'renders the path chooser on the start screen' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.paths.new.title'))
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.paths.standalone.title'))
      end

      it 'records the chosen path and advances to item_start' do
        patch deposit_wizard_advance_path(step: 'start'), params: { path: 'standalone' }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'item_start'))
        expect(session[:deposit_wizard]['path']).to eq('standalone')
      end

      it 'advances item_start to the type chooser' do
        patch deposit_wizard_advance_path(step: 'item_start')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      it 'persists the chosen work type on known_type' do
        patch deposit_wizard_advance_path(step: 'known_type'), params: { work_type: work_type }

        expect(session[:deposit_wizard]['work_type']).to eq(work_type)
      end
    end

    describe 'the inline admin-set choice' do
      it 'records an admin set submitted with the start choice' do
        admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
        patch deposit_wizard_advance_path(step: 'start'),
              params: { work_type: work_type, admin_set_id: admin_set_id }

        expect(session[:deposit_wizard]['admin_set_id']).to eq(admin_set_id)
      end
    end

    describe 'the files step' do
      it 'redirects back to type selection when no work type has been chosen' do
        get deposit_wizard_step_path(step: 'files')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      context 'after a work type is chosen' do
        before { patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type } }

        it 'renders the files step with the uploader' do
          get deposit_wizard_step_path(step: 'files')

          expect(response).to have_http_status(:success)
          expect(response.body).to include('fileupload-deposit-wizard')
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.files.heading'))
        end

        it 'stores uploaded file ids and the primary selection, then advances to details' do
          patch deposit_wizard_advance_path(step: 'files'),
                params: { uploaded_files: %w[3 7], primary_file_id: '7' }

          expect(session[:deposit_wizard]['uploaded_file_ids']).to eq(%w[3 7])
          expect(session[:deposit_wizard]['primary_file_id']).to eq('7')
          expect(response).to redirect_to(deposit_wizard_step_path(step: 'details'))
        end
      end
    end

    describe 'the details step' do
      it 'redirects back to type selection when no work type has been chosen' do
        get deposit_wizard_step_path(step: 'details')

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end

      context 'after a work type is chosen' do
        before { patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type } }

        it 'renders the metadata form and the visibility component' do
          get deposit_wizard_step_path(step: 'details')

          expect(response).to have_http_status(:success)
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.details.heading'))
          expect(response.body).to include("#{param_key}[title]")
          expect(response.body).to include("#{param_key}[visibility]")
        end

        it 'persists valid metadata and advances' do
          patch deposit_wizard_advance_path(step: 'details'),
                params: { param_key => { title: ['A guided deposit work'], creator: ['Ada Lovelace'] } }

          expect(session[:deposit_wizard]['attributes']['title']).to eq(['A guided deposit work'])
          expect(response).to redirect_to(deposit_wizard_step_path(step: 'review'))
        end

        it 're-renders the form when required metadata is missing' do
          patch deposit_wizard_advance_path(step: 'details'),
                params: { param_key => { title: [''] } }

          expect(response).to have_http_status(:success)
          expect(session[:deposit_wizard]['attributes']).to be_nil
        end
      end
    end

    describe 'review and commit' do
      before do
        Hyrax::AdminSetCreateService.find_or_create_default_admin_set
        # Pin the deposit-agreement flags off by default so commit isn't gated;
        # the active-acceptance context turns them on explicitly.
        allow(Flipflop).to receive(:show_deposit_agreement?).and_return(false)
        allow(Flipflop).to receive(:active_deposit_agreement_acceptance?).and_return(false)
      end

      # Walk to a valid review state: choose a type (the admin set defaults),
      # then submit required metadata.
      def fill_in_wizard
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }
        patch deposit_wizard_advance_path(step: 'details'),
              params: { param_key => { title: ['Repair Study'], creator: ['Ada Lovelace'] } }
      end

      it 'renders a summary including visibility on the review step' do
        fill_in_wizard
        get deposit_wizard_step_path(step: 'review')

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.review.heading'))
        expect(response.body).to include('Repair Study')
        expect(response.body).to include(I18n.t('hyku.deposit_wizard.review.visibility'))
        expect(response.body).to include('administrative set')
      end

      context 'when the deposit agreement is in active-acceptance mode' do
        before do
          allow(Flipflop).to receive(:show_deposit_agreement?).and_return(true)
          allow(Flipflop).to receive(:active_deposit_agreement_acceptance?).and_return(true)
        end

        it 'blocks the commit until the agreement is accepted' do
          fill_in_wizard

          post deposit_wizard_commit_path

          expect(response).to have_http_status(:success)
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.errors.agreement_required'))
          expect(response).not_to redirect_to(deposit_wizard_step_path(step: 'done'))
        end

        it 'commits when the agreement checkbox is accepted' do
          fill_in_wizard

          post deposit_wizard_commit_path, params: { agreement: '1' }

          expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
        end
      end

      it 'commits the work and lands on the done screen' do
        fill_in_wizard
        resource_class = Hyrax::ModelRegistry.work_classes
                                             .detect { |k| k < Hyrax::Resource && k.model_name.param_key == param_key }

        expect { post deposit_wizard_commit_path }
          .to change { Hyrax.query_service.find_all_of_model(model: resource_class).count }.by(1)

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'done'))
        expect(session[:deposit_wizard]).to eq({})
      end

      it 'runs the configured post-commit hook with the persisted work' do
        captured = []
        Hyku::DepositWizard.config.post_commit = ->(work, _state) { captured << work }
        fill_in_wizard

        post deposit_wizard_commit_path

        expect(captured.size).to eq(1)
        expect(captured.first).to be_present
      ensure
        Hyku::DepositWizard.reset_config!
      end

      it 'redirects to type selection when committing without a work type' do
        post deposit_wizard_commit_path

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
      end
    end
  end

  describe 'the Guided Deposit button on the works page' do
    # A default admin set grants the admin work-create ability, which the button
    # (like the stock "Add new work" button) is gated on.
    before { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

    it 'appears when the feature is on' do
      allow(Flipflop).to receive(:deposit_wizard?).and_return(true)

      get hyrax.my_works_path

      expect(response.body).to include('guided-deposit-button')
      expect(response.body).to include(I18n.t('hyku.deposit_wizard.button'))
    end

    it 'is absent when the feature is off' do
      allow(Flipflop).to receive(:deposit_wizard?).and_return(false)

      get hyrax.my_works_path

      expect(response.body).not_to include('guided-deposit-button')
    end
  end
end
