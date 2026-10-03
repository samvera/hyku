# frozen_string_literal: true

# Makes every DisplayImagePresenter report a displayable image, bypassing the
# file-storage stack, so manifests can be built from bare file sets. It stays
# prepended once added, which is why specs share this one module.
module DisplayableFileSets
  def display_image
    IIIFManifest::DisplayImage.new(id.to_s, width: 640, height: 480, format: 'image/png', iiif_endpoint: nil)
  end

  def display_content
    IIIFManifest::V3::DisplayContent.new(id.to_s, width: 640, height: 480, type: 'Image')
  end
end

RSpec.shared_context 'with displayable file sets' do
  before(:all) { Hyrax::IiifManifestPresenter::DisplayImagePresenter.prepend(DisplayableFileSets) } # rubocop:disable RSpec/BeforeAfterAll
end
