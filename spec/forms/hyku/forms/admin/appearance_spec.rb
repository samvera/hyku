# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyku::Forms::Admin::Appearance do
  let(:instance) { described_class.new }

  def count_queries(&block)
    count = 0
    counter = ->(*, **) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  describe 'database query efficiency' do
    it 'loads all content blocks in a single query regardless of how many attributes are accessed' do
      query_count = count_queries do
        instance.link_color
        instance.navbar_background_color
        instance.primary_button_background_color
        instance.body_font
        instance.custom_css_block
      end
      # 1 query to load all ContentBlocks in a single IN clause.
      # Rails may also fire a pg_attribute schema introspection query on first use;
      # we allow for that here rather than fighting the schema cache warmup.
      expect(query_count).to be <= 2
    end
  end
  describe '.default_fonts' do
    subject { described_class.default_fonts }

    it { is_expected.to be_a(Hash) }

    it "has the 'body_font' and 'headline_font' keys" do
      expect(subject.keys).to match_array(['body_font', 'headline_font'])
    end
  end

  describe '.default_colors' do
    subject { described_class.default_colors }

    it { is_expected.to be_a(Hash) }
  end

  describe '.image_params' do
    subject { described_class.image_params }

    it { is_expected.to be_an(Array) }
  end

  describe '#banner_image' do
    subject { instance.banner_image }

    it { is_expected.to be_a(Hyku::AvatarUploader) }
  end

  described_class.instance_methods.grep(/_color$/).each do |color_method_name|
    describe "##{color_method_name}" do
      subject { instance.send(color_method_name) }

      it { is_expected.to match(/^#[0-9A-F]{6}/i) }
    end
  end
end
