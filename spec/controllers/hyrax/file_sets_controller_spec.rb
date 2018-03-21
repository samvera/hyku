RSpec.describe Hyrax::FileSetsController do
  describe 'show_presenter' do
    subject { described_class.show_presenter }

    it { is_expected.to eq Hyku::FileSetPresenter }
  end
end
