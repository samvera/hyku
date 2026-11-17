# frozen_string_literal: true

RSpec.describe 'Riiif placeholder images' do
  it 'opens the not found and unauthorized images with the loaders libvips still trusts' do
    [Riiif.not_found_image, Riiif.unauthorized_image].each do |path|
      expect(Vips::Image.new_from_file(path.to_s).width).to be_positive
    end
  end
end
