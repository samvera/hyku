# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Image`

RSpec.describe Image do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq ImageIndexer }
  end

  describe 'class configuration' do
    subject { described_class }

    its(:migrating_from) { is_expected.to eq(Image) }
    its(:migrating_to) { is_expected.to eq(ImageResource) }

    context '.model_name' do
      subject { described_class.model_name }

      its(:klass) { is_expected.to eq Image }
      its(:name) { is_expected.to eq "Image" }

      its(:singular) { is_expected.to eq "image" }
      its(:plural) { is_expected.to eq "images" }
      its(:element) { is_expected.to eq "image" }
      its(:human) { is_expected.to eq "Image" }
      its(:collection) { is_expected.to eq "images" }
      its(:param_key) { is_expected.to eq "image" }
      its(:i18n_key) { is_expected.to eq :image }
      its(:route_key) { is_expected.to eq "hyrax_images" }
      its(:singular_route_key) { is_expected.to eq "hyrax_image" }
    end
  end
end
