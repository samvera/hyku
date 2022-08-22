# frozen_string_literal: true

RSpec.describe User, type: :model do
  it 'validates email and password' do
    expect(subject).to validate_presence_of(:email)
    expect(subject).to validate_presence_of(:password)
  end

  context 'the first created user in global tenant' do
    subject { create(:base_user) }

    before do
      allow(Account).to receive(:global_tenant?).and_return true
    end

    it 'does not get the admin role' do
      expect(subject.persisted?).to be true
      expect(subject).not_to have_role :admin
    end
  end

  context 'the first created user on a tenant' do
    subject { create(:base_user) }

    it 'is given the admin role' do
      expect(subject.persisted?).to be true
      expect(subject).to have_role :admin, Site.instance
    end
  end

  context 'a subsequent user' do
    let!(:first_user) { create(:base_user) }
    let!(:next_user) { create(:base_user) }

    it 'does not get the admin role' do
      expect(next_user.persisted?).to be true
      expect(next_user).not_to have_role :admin
    end
  end

  describe '#site_roles' do
    subject { create(:admin) }

    it 'fetches the global roles assigned to the user' do
      expect(subject.site_roles.pluck(:name)).to match_array ['admin', 'registered']
    end
  end

  describe '#site_roles=' do
    subject { create(:user) }

    it 'assigns global roles to the user' do
      expect(subject.site_roles.pluck(:name)).to match_array ['registered']

      subject.update(site_roles: ['admin', 'registered'])

      expect(subject.site_roles.pluck(:name)).to match_array ['admin', 'registered']
    end

    it 'removes roles' do
      subject.update(site_roles: ['admin'])
      subject.update(site_roles: [])
      expect(subject.site_roles.pluck(:name)).to be_empty
    end
  end
end
