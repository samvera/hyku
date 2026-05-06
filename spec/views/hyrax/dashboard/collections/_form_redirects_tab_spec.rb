# frozen_string_literal: true

# Hyku overrides the collection form partial to add a Redirects tab.
# This spec verifies the tab appears when the feature is active and
# the form is a persisted ResourceForm whose model carries :redirects.
RSpec.describe 'hyrax/dashboard/collections/_form.html.erb', type: :view do
  let(:collection) { FactoryBot.valkyrie_create(:hyku_collection, with_permission_template: true) }
  let(:collection_form) { Hyrax::Forms::ResourceForm.for(resource: collection) }
  let(:banner_info) { { file: "", alttext: "" } }
  let(:logo_info) { [] }

  before do
    controller.request.path_parameters[:id] = collection.id.to_s
    assign(:form, collection_form)
    assign(:collection, collection)
    assign(:banner_info, banner_info)
    assign(:logo_info, logo_info)

    # Stub collection type helpers that the form checks for persisted collections
    allow(view).to receive(:collection_brandable?).and_return(false)
    allow(view).to receive(:collection_discoverable?).and_return(false)
    allow(view).to receive(:collection_sharable?).and_return(false)
    allow(view).to receive(:thumbnail_label_for).and_return('Default thumbnail')

    allow(collection_form).to receive(:display_additional_fields?).and_return(false)
  end

  context 'when redirects feature is active and model supports redirects', clean: true do
    before do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
      allow(collection).to receive(:respond_to?).and_call_original
      allow(collection).to receive(:respond_to?).with(:redirects).and_return(true)
      # Stub the inner Hyrax partial so we only test Hyku's tab structure,
      # not Hyrax's form_redirects partial (which needs a real redirects attribute).
      stub_template 'hyrax/base/_form_redirects.html.erb' => '<div class="stubbed-redirects-form">redirects form</div>'
    end

    it 'renders the Redirects tab link' do
      render
      expect(rendered).to have_link('Aliases', href: '#redirects')
    end

    it 'renders the redirects tab pane' do
      render
      expect(rendered).to have_selector('div#redirects.tab-pane')
    end
  end

  context 'when redirects feature is inactive', clean: true do
    before do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(false)
    end

    it 'does not render the Redirects tab link' do
      render
      expect(rendered).not_to have_link('Aliases', href: '#redirects')
    end

    it 'does not render the redirects tab pane' do
      render
      expect(rendered).not_to have_selector('div#redirects')
    end
  end

  context 'when the collection is not persisted', clean: true do
    let(:collection) { FactoryBot.build(:collection_resource) }

    before do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
      controller.request.path_parameters[:id] = 'new'
    end

    it 'does not render the Redirects tab (tabs only appear on edit)' do
      render
      expect(rendered).not_to have_link('Aliases', href: '#redirects')
    end
  end
end
