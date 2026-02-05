# frozen_string_literal: true

RSpec.describe Proprietor::AccountPresenter do
  subject(:presenter) { described_class.new(account) }

  let(:account) { instance_double(Account, cname: 'example', admin_emails: admin_emails, superadmin_emails: superadmin_emails, public_demo_tenant: public_demo_tenant) }
  let(:admin_emails) { ['admin1@example.com', 'admin2@example.com'] }
  let(:superadmin_emails) { ['superadmin1@example.com', 'superadmin2@example.com'] }
  let(:public_demo_tenant) { false }

  describe '#cname' do
    it 'delegates to account' do
      expect(presenter.cname).to eq('example')
    end
  end

  describe '#admin_emails' do
    it 'delegates to account' do
      expect(presenter.admin_emails).to eq(admin_emails)
    end
  end

  describe '#superadmin_emails' do
    it 'delegates to account' do
      expect(presenter.superadmin_emails).to eq(superadmin_emails)
    end
  end

  describe '#last_admin?' do
    context 'when there is only one admin' do
      let(:admin_emails) { ['admin@example.com'] }

      it 'returns true' do
        expect(presenter.last_admin?).to be true
      end
    end

    context 'when there are multiple admins' do
      it 'returns false' do
        expect(presenter.last_admin?).to be false
      end
    end
  end

  describe '#last_superadmin?' do
    let(:user) { instance_double(User, email: 'superadmin1@example.com') }

    context 'when there is only one superadmin and user is that superadmin' do
      let(:superadmin_emails) { ['superadmin1@example.com'] }

      it 'returns true' do
        expect(presenter.last_superadmin?(user)).to be true
      end
    end

    context 'when there is only one superadmin but user is not that superadmin' do
      let(:superadmin_emails) { ['other@example.com'] }

      it 'returns false' do
        expect(presenter.last_superadmin?(user)).to be false
      end
    end

    context 'when there are multiple superadmins' do
      it 'returns false' do
        expect(presenter.last_superadmin?(user)).to be false
      end
    end
  end

  describe '#superadmin?' do
    context 'when user is a superadmin' do
      let(:user) { instance_double(User, email: 'superadmin1@example.com') }

      it 'returns true' do
        expect(presenter.superadmin?(user)).to be true
      end
    end

    context 'when user is not a superadmin' do
      let(:user) { instance_double(User, email: 'regular@example.com') }

      it 'returns false' do
        expect(presenter.superadmin?(user)).to be false
      end
    end
  end

  describe '#can_remove_admin?' do
    let(:user) { instance_double(User, email: 'admin1@example.com') }

    context 'when there are multiple admins' do
      it 'returns true' do
        expect(presenter.can_remove_admin?(user)).to be true
      end
    end

    context 'when there is only one admin' do
      let(:admin_emails) { ['admin@example.com'] }

      it 'returns false' do
        expect(presenter.can_remove_admin?(user)).to be false
      end
    end
  end

  describe '#can_remove_superadmin?' do
    context 'when user is the last superadmin on a public demo tenant' do
      let(:user) { instance_double(User, email: 'superadmin1@example.com') }
      let(:superadmin_emails) { ['superadmin1@example.com'] }
      let(:public_demo_tenant) { true }

      it 'returns false' do
        expect(presenter.can_remove_superadmin?(user)).to be false
      end
    end

    context 'when user is the last superadmin on a non-demo tenant' do
      let(:user) { instance_double(User, email: 'superadmin1@example.com') }
      let(:superadmin_emails) { ['superadmin1@example.com'] }
      let(:public_demo_tenant) { false }

      it 'returns true' do
        expect(presenter.can_remove_superadmin?(user)).to be true
      end
    end

    context 'when user is not the last superadmin' do
      let(:user) { instance_double(User, email: 'superadmin1@example.com') }

      it 'returns true' do
        expect(presenter.can_remove_superadmin?(user)).to be true
      end
    end
  end

  describe '#admin_emails_without' do
    let(:user) { instance_double(User, email: 'admin1@example.com') }

    it 'returns admin emails excluding the given user' do
      expect(presenter.admin_emails_without(user)).to eq(['admin2@example.com'])
    end
  end

  describe '#superadmin_emails_without' do
    let(:user) { instance_double(User, email: 'superadmin1@example.com') }

    it 'returns superadmin emails excluding the given user' do
      expect(presenter.superadmin_emails_without(user)).to eq(['superadmin2@example.com'])
    end
  end

  describe '#superadmin_emails_with' do
    let(:user) { instance_double(User, email: 'newadmin@example.com') }

    it 'returns superadmin emails including the given user' do
      expect(presenter.superadmin_emails_with(user)).to match_array(['superadmin1@example.com', 'superadmin2@example.com', 'newadmin@example.com'])
    end
  end
end
