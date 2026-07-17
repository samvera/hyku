# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::VisibilityPolicy do
  described = Hyku::DepositWizard::VisibilityPolicy
  open = described::OPEN
  authenticated = described::AUTHENTICATED
  embargo = described::EMBARGO
  lease = described::LEASE
  restricted = described::PRIVATE

  def policy(data)
    described_class.from_admin_set_data(data)
  end

  describe '#allowed_visibilities' do
    it 'allows everything when the admin set has no restrictions' do
      expect(policy({}).allowed_visibilities).to eq(described_class::ALL)
    end

    it 'forces a single visibility when release is immediate and a visibility is required' do
      result = policy('data-release-no-delay' => 'true', 'data-visibility' => open).allowed_visibilities
      expect(result).to eq([open])
    end

    it 'drops embargo and lease when release is immediate with no required visibility' do
      result = policy('data-release-no-delay' => 'true').allowed_visibilities
      expect(result).to contain_exactly(open, authenticated, restricted)
    end

    it 'requires embargo for an exact future release date' do
      future = (Time.zone.today + 30).to_s
      result = policy('data-release-date' => future).allowed_visibilities
      expect(result).to eq([embargo])
    end

    it 'allows the required visibility or embargo for a release-before window' do
      future = (Time.zone.today + 30).to_s
      result = policy('data-release-date' => future,
                      'data-release-before-date' => 'true',
                      'data-visibility' => authenticated).allowed_visibilities
      expect(result).to contain_exactly(authenticated, embargo)
    end

    it 'allows all but lease for a release-before window with no required visibility' do
      future = (Time.zone.today + 30).to_s
      result = policy('data-release-date' => future, 'data-release-before-date' => 'true').allowed_visibilities
      expect(result).not_to include(lease)
      expect(result).to include(open, embargo)
    end

    it 'treats a past release date as release-now' do
      past = (Time.zone.today - 5).to_s
      result = policy('data-release-date' => past).allowed_visibilities
      expect(result).not_to include(embargo, lease)
    end
  end

  describe '#forced_embargo_date' do
    it 'is the exact date for a required embargo' do
      future = (Time.zone.today + 30).to_s
      expect(policy('data-release-date' => future).forced_embargo_date).to eq(future)
    end

    it 'is nil when the date is only a ceiling' do
      future = (Time.zone.today + 30).to_s
      expect(policy('data-release-date' => future, 'data-release-before-date' => 'true').forced_embargo_date).to be_nil
    end
  end
end
