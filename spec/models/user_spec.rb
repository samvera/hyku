RSpec.describe User, type: :model do
  before do
    allow_any_instance_of(described_class).to receive(:default_tenant?).and_return(false)
  end

  context 'in a multitenant environment' do
    before do
      allow_any_instance_of(described_class).to receive(:default_tenant?).and_return(true)
    end

    subject { FactoryGirl.create(:base_user) }

    it 'is given the superadmin role' do
      expect(subject).to have_role :superadmin
    end
  end

  context 'the first created user' do
    subject { FactoryGirl.create(:base_user) }
    it 'is given the admin role' do
      expect(subject).to have_role :admin, Site.instance
    end
  end

  context 'a subsequent user' do
    let!(:first_user) { FactoryGirl.create(:base_user) }
    let!(:next_user) { FactoryGirl.create(:base_user) }

    it 'does not get the admin role' do
      expect(next_user).not_to have_role :admin
    end
  end

  describe '#site_roles' do
    subject { FactoryGirl.create(:admin) }

    it 'fetches the global roles assigned to the user' do
      expect(subject.site_roles.pluck(:name)).to match_array ['admin']
    end
  end

  describe '#site_roles=' do
    subject { FactoryGirl.create(:user) }

    it 'assigns global roles to the user' do
      expect(subject.site_roles.pluck(:name)).to be_empty

      subject.update(site_roles: ['admin'])

      expect(subject.site_roles.pluck(:name)).to match_array ['admin']
    end

    it 'removes roles' do
      subject.update(site_roles: ['admin'])
      subject.update(site_roles: [])
      expect(subject.site_roles.pluck(:name)).to be_empty
    end
  end
end
