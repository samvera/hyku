# frozen_string_literal: true

RSpec.describe 'Deposit wizard modes', type: :request, singletenant: true, clean: true do
  let(:admin) { FactoryBot.create(:admin) }

  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    login_as admin
    # Guided must be on for the start screen (and thus the standard-form link) to exist.
    allow(Flipflop).to receive(:enable_guided_deposit?).and_return(true)
  end

  # The works-page button rendering is covered as a view spec
  # (spec/views/hyrax/my/works/_deposit_actions.html.erb_spec.rb). Here we exercise
  # the standard-form link on the guided start screen, gated by config.standard_link?
  # (both guided and standard deposit enabled).
  describe 'the standard-form link on the guided start screen (GET /deposit_wizard)' do
    context 'when standard deposit is disabled (guided only)' do
      before { allow(Flipflop).to receive(:enable_standard_deposit?).and_return(false) }

      it 'does not offer a link to the standard form' do
        get deposit_wizard_path

        expect(response.body).not_to include(I18n.t('hyku.deposit_wizard.start.standard_link'))
      end
    end

    context 'when standard deposit is also enabled' do
      before { allow(Flipflop).to receive(:enable_standard_deposit?).and_return(true) }

      it 'offers a link to the standard form' do
        get deposit_wizard_path

        expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.standard_link'))
      end

      context 'with several creatable work types' do
        before { allow_any_instance_of(Hyrax::SelectTypeListPresenter).to receive(:many?).and_return(true) }

        it 'routes the link through the standard type chooser modal' do
          get deposit_wizard_path

          expect(response.body).to include('data-behavior="select-work"')
          expect(response.body).to include('id="worktypes-to-create"')
        end

        it 'shows the admin-set dropdown in the chooser when assign_admin_set is on' do
          allow(Flipflop).to receive(:assign_admin_set?).and_return(true)
          get deposit_wizard_path

          expect(response.body).to include('select-work-admin-set')
        end
      end

      context 'with a single creatable work type' do
        before { allow_any_instance_of(Hyrax::SelectTypeListPresenter).to receive(:many?).and_return(false) }

        it 'links straight to the standard new-work form (no chooser modal)' do
          get deposit_wizard_path

          expect(response.body).not_to include('id="worktypes-to-create"')
          expect(response.body).to include(I18n.t('hyku.deposit_wizard.start.standard_link'))
          expect(response.body).not_to include('data-behavior="select-work"')
        end
      end
    end
  end
end
