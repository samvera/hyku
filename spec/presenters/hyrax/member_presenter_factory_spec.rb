require 'rails_helper'

RSpec.describe Hyrax::MemberPresenterFactory do
  before do
    # Trigger autoloading
    Hyku::ManifestEnabledWorkShowPresenter
  end

  describe "file_presenter_class" do
    subject { described_class.file_presenter_class }

    it { is_expected.to eq Hyku::FileSetPresenter }
  end
end
