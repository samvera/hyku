# frozen_string_literal: true

# The OER form carries its own copy of this field, so the retired-term handling the
# records/ partial is checked for has to be confirmed here too rather than assumed.
RSpec.describe 'oers/edit_fields/_resource_type', type: :view do
  let(:work) { OerResource.new }
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }
  let(:active_term) { Hyrax::OerTypesService.select_active_options.first.last }

  def render_field
    view.simple_form_for(form, url: '/') do |f|
      concat render(partial: 'oers/edit_fields/resource_type', locals: { f: f, key: :resource_type })
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

  # Hyrax::OerForm lists resource_type in required_fields, so unlike the records/
  # partial there is no blank to choose: include_blank follows required?.
  it 'offers no blank, because an OER must carry a resource type' do
    render_field

    expect(rendered).to have_no_css("option[value='']")
  end
end
