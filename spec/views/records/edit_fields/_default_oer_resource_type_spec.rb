# frozen_string_literal: true

# An OER work resolves resource_type to oer_types where every other work type
# resolves it to resource_types, so the generic partial is exercised with an OER
# to confirm the model reaches the authority lookup.
RSpec.describe 'records/edit_fields/_default with an OER resource_type', type: :view do
  let(:work) { OerResource.new }
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }
  let(:active_term) { Hyrax::OerTypesService.select_active_options.first.last }

  def render_field
    view.simple_form_for(form, url: '/') do |f|
      concat render(partial: 'records/edit_fields/default', locals: { f: f, key: :resource_type })
    end
  end

  before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

  context 'when the work stores a term that is no longer offered' do
    before { form.resource_type = ['Retired Thing'] }

    it 'offers the retired term' do
      render_field

      expect(rendered).to have_css("option[value='Retired Thing']")
    end

    it 'shows the retired term as selected' do
      render_field

      expect(rendered).to have_css("option[value='Retired Thing'][selected]")
    end
  end

  context 'when the work stores an active term' do
    before { form.resource_type = [active_term] }

    it 'shows it as selected' do
      render_field

      expect(rendered).to have_css("option[value='#{active_term}'][selected]")
    end

    it 'does not duplicate it' do
      render_field

      expect(rendered).to have_css("option[value='#{active_term}']", count: 1)
    end
  end

  it 'offers the terms from oer_types rather than the general authority' do
    render_field

    expect(rendered).to have_css("option[value='InteractiveResource']")
    expect(rendered).to have_no_css("option[value='Article']")
  end

  # Hyrax::OerForm lists resource_type in required_fields, so include_blank
  # follows required? and there is no blank to choose.
  it 'offers no blank, because an OER must carry a resource type' do
    render_field

    expect(rendered).to have_no_css("option[value='']")
  end
end
