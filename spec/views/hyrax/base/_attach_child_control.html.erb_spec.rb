# frozen_string_literal: true

RSpec.describe 'hyrax/base/_attach_child_control.html.erb', type: :view do
  let(:concern) { GenericWorkResource }
  let(:presenter) { double('WorkShowPresenter', id: 'parent-9', valid_child_concerns: [concern]) }

  def render_control
    render 'hyrax/base/attach_child_control', presenter: presenter
  end

  context 'when guided replaces the standard deposit' do
    before { allow(view).to receive(:guided_replaces_standard?).and_return(true) }

    it 'renders a single link into the wizard with the parent seeded' do
      render_control

      expect(rendered).to have_link(I18n.t('hyrax.base.show_actions.attach_child'),
                                    href: main_app.deposit_wizard_path(parent_id: 'parent-9'))
    end

    it 'does not render a work-type dropdown' do
      render_control

      expect(rendered).not_to have_selector('.dropdown-menu')
    end
  end

  context 'when guided does not replace the standard deposit' do
    before { allow(view).to receive(:guided_replaces_standard?).and_return(false) }

    it 'renders the per-concern dropdown into the stock nested-new form' do
      render_control

      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_link(
        "Attach #{concern.human_readable_type}",
        href: polymorphic_path([main_app, :new, :hyrax, :parent, concern.model_name.singular.to_sym],
                               parent_id: 'parent-9')
      )
    end

    it 'does not link to the wizard' do
      render_control

      expect(rendered).not_to have_link(href: main_app.deposit_wizard_path(parent_id: 'parent-9'))
    end
  end
end
