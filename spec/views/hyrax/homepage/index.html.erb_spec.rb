# frozen_string_literal: true

RSpec.describe 'hyrax/homepage/index.html.erb', type: :view do
  let(:presenter) do
    double('HomepagePresenter', display_share_button?: true,
                                create_many_work_types?: false, first_work_type: GenericWorkResource,
                                draw_select_work_modal?: false)
  end

  before do
    assign(:presenter, presenter)
    allow(view).to receive(:signed_in?).and_return(true)
    allow(Flipflop).to receive(:read_only?).and_return(false)
    allow(view).to receive(:application_name).and_return('App')
    # Isolate the share button from the home-content section.
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with('home_content').and_return('')
  end

  context 'when guided replaces the standard deposit' do
    before { allow(view).to receive(:guided_replaces_standard?).and_return(true) }

    it 'points the share-your-work button at the wizard' do
      render template: 'hyrax/homepage/index'

      expect(rendered).to have_link(I18n.t('hyrax.share_button'),
                                    href: main_app.deposit_wizard_path)
    end
  end

  context 'when guided does not replace the standard deposit' do
    before { allow(view).to receive(:guided_replaces_standard?).and_return(false) }

    it 'points the share-your-work button at the stock new-work form' do
      render template: 'hyrax/homepage/index'

      expect(rendered).to have_link(I18n.t('hyrax.share_button'),
                                    href: new_polymorphic_path([main_app, GenericWorkResource]))
    end
  end
end
