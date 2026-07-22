# frozen_string_literal: true

RSpec.describe 'hyrax/my/works/_deposit_actions.html.erb', type: :view do
  let(:create_work_presenter) { double('SelectTypeListPresenter', many?: false, first_model: GenericWorkResource) }

  before do
    assign(:create_work_presenter, create_work_presenter)
    allow(view).to receive(:current_ability).and_return(double(can_create_any_work?: true))
    allow(view).to receive(:show_guided_deposit_button?).and_return(guided)
    allow(view).to receive(:show_standard_deposit_button?).and_return(standard)
    # Isolate the button branching from the unrelated batch-upload path.
    allow(Flipflop).to receive(:batch_upload?).and_return(false)
    render
  end

  context 'standard only (default)' do
    let(:guided) { false }
    let(:standard) { true }

    it 'shows the standard "Add new work" button to the standard form, no guided button' do
      expect(rendered).not_to have_selector('a#guided-deposit-button')
      expect(rendered).to have_link(I18n.t('helpers.action.work.new'),
                                    href: new_polymorphic_path([main_app, GenericWorkResource]))
    end
  end

  context 'guided only' do
    let(:guided) { true }
    let(:standard) { false }

    it 'shows the Guided Deposit button and no standard button' do
      expect(rendered).to have_link(I18n.t('hyku.deposit_wizard.button'),
                                    href: main_app.deposit_wizard_path)
      expect(rendered).not_to have_selector('a#add-new-work-button')
    end
  end

  context 'both enabled' do
    let(:guided) { true }
    let(:standard) { true }

    it 'shows both buttons; the standard button still targets the standard form' do
      expect(rendered).to have_link(I18n.t('hyku.deposit_wizard.button'),
                                    href: main_app.deposit_wizard_path)
      expect(rendered).to have_selector('a#guided-deposit-button')
      expect(rendered).to have_link(I18n.t('helpers.action.work.new'),
                                    href: new_polymorphic_path([main_app, GenericWorkResource]))
    end
  end

  context 'neither enabled' do
    let(:guided) { false }
    let(:standard) { false }

    it 'shows no deposit buttons' do
      expect(rendered).not_to have_selector('a#guided-deposit-button')
      expect(rendered).not_to have_selector('a#add-new-work-button')
    end
  end
end
