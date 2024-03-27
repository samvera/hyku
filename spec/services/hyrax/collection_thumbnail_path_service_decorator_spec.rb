# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::CollectionThumbnailPathService do
  describe '.default_image' do
    context 'super_method' do
      it 'is in Hyrax' do
        source_location = described_class.method(:default_image).super_method.source_location[0]
        expect(source_location).to eq(Hyrax::Engine.root.join("app", "services", "hyrax", "collection_thumbnail_path_service.rb").to_s)
      end
    end
  end
end
