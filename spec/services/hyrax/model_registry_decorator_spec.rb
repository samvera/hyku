# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::ModelRegistry do
  describe '.work_class_names' do
    subject { described_class.work_class_names }

    it { is_expected.to include("ImageResource") }
    it { is_expected.to include("GenericWorkResource") }
  end
end
