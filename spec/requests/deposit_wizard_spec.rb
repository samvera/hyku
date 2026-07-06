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
