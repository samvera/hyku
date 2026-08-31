# frozen_string_literal: true

# A term retired after a work stored it has no option of its own, so the browser posts
# the select without it and the value is lost on the next save. These render the real
# partial to confirm the option is both present and selected.
RSpec.describe 'records/edit_fields/_resource_type', type: :view do
  let(:work) { ImageResource.new }
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }
  let(:active_term) { Hyrax::ResourceTypesService.select_active_options.first.last }

  def render_field
    # simple_form_for rather than a double: the point is what Simple Form renders.
    view.simple_form_for(form, url: '/') do |f|
      concat render(partial: 'records/edit_fields/resource_type', locals: { f: f, key: :resource_type })
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

    it 'still offers the active terms' do
      render_field

      expect(rendered).to have_css("option[value='#{active_term}']")
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

  context 'when the work stores nothing' do
    it 'offers a blank, because a resource type is optional' do
      render_field

      expect(rendered).to have_css("option[value='']")
    end
  end
end
