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

    # A work type the current user is actually allowed to create.
    let(:work_type) do
      Hyrax::QuickClassificationQuery.new(admin).authorized_models.first.to_s
    end

    after { Hyku::DepositWizard.reset_config! }

    context 'with a flat config (no container)' do
      before { Hyku::DepositWizard.reset_config! }

      it 'renders a work-type chooser on the start screen' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.known_type.heading'))
      end

      it 'persists the chosen work type and advances' do
        patch deposit_wizard_advance_path(step: 'start'), params: { work_type: work_type }

        expect(response).to redirect_to(deposit_wizard_step_path(step: 'known_type'))
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
