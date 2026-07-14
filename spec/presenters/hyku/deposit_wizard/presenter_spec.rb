# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::Presenter do
  subject(:presenter) { described_class.new(context) }

  # Stands in for the controller the presenter delegates request primitives to.
  let(:context) do
    double(session: session, current_user: nil, current_ability: nil,
           params: {}, main_app: nil, blacklight_config: nil)
  end
  let(:session) { {} }

  after { Hyku::DepositWizard.reset_config! }

  describe '#config' do
    it 'returns the shared wizard config' do
      expect(presenter.config).to be(Hyku::DepositWizard.config)
    end
  end

  describe '#state' do
    it 'wraps the session-backed wizard state' do
      expect(presenter.state).to be_a(Hyku::DepositWizard::State)
    end

    it 'memoizes a single state instance' do
      expect(presenter.state).to be(presenter.state)
    end
  end
end
