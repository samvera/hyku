# frozen_string_literal: true

RSpec.describe SearchBuilder do
  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include :filter_models }
  end
end
