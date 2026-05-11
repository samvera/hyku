# frozen_string_literal: true

# This spec verifies that the ResourceForm exposes a `redirects` property
# when the redirects feature is enabled. The form partial
# `_form_redirects.html.erb` calls `f.object.redirects` (line 21), so
# the form MUST have this property — not just `redirects_attributes`.
#
# Context: In HYRAX_FLEXIBLE=false mode (the default in this test suite),
# Hyrax::Schema(:redirects) adds the attribute to the model but
# RedirectsFieldBehavior only adds `redirects_attributes` (virtual) to
# the form. The form crashes with NoMethodError when the Aliases tab
# tries to render.
#
# Upstream bug: RedirectsFieldBehavior.included needs to also define
# `property :redirects` on the form when redirects_enabled? is true.
#
# See: spec/redirects_testing/TEST_RESULTS_PASS1.md for the full bug report.
RSpec.describe 'Redirects form property', type: :model do
  before do
    allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
  end

  describe 'GenericWorkResource model' do
    it 'has the redirects attribute' do
      expect(GenericWorkResource.new).to respond_to(:redirects)
    end
  end

  describe 'ResourceForm for GenericWorkResource' do
    let(:resource) { GenericWorkResource.new }
    let(:form) { Hyrax::Forms::ResourceForm.for(resource) }

    it 'has the redirects_attributes virtual property from RedirectsFieldBehavior' do
      expect(form).to respond_to(:redirects_attributes)
    end

    it 'has the redirects property so _form_redirects.html.erb can render' do
      expect(form).to respond_to(:redirects),
        "Expected #{form.class} to respond to :redirects, but it doesn't. " \
        "The model (#{resource.class}) does respond to :redirects. " \
        "RedirectsFieldBehavior needs to add `property :redirects` to the form " \
        "when redirects_enabled? is true, not just `redirects_attributes`."
    end
  end
end
