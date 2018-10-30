require 'rake'

RSpec.describe "Rake tasks" do
  before(:all) do
    Rails.application.load_tasks
  end

  describe "hyku:upgrade:clean_migrations" do
    it 'requires a datesub argument'

    it 'removes unnecessary migrations' do
      original_migrations = Dir.glob(Rails.root.join('db', 'migrate', '*.rb'))
      time = Time.now.utc.strftime("%Y%m%d%H")
      run_task('hyrax:install:migrations')
      run_task('hyku:upgrade:clean_migrations', time)
      new_migrations = Dir.glob(Rails.root.join('db', 'migrate', '*.rb'))
      expect(new_migrations).to eq(original_migrations)
    end
  end

  describe "superadmin:grant" do
    let!(:user1) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user) }

    before do
      user1.remove_role :superadmin
      user2.remove_role :superadmin
    end

    it 'requires user_list argument' do
      expect { run_task('hyku:superadmin:grant') }.to raise_error(ArgumentError)
    end

    it 'warns when a user is not found' do
      expect(run_task('hyku:superadmin:grant', 'missing@example.org')).to include 'Could not find user'
    end

    it 'grants a single user the superadmin role' do
      run_task('hyku:superadmin:grant', user1.email)
      expect(user1.has_role?(:superadmin)).to eq true
      expect(user2.has_role?(:superadmin)).to eq false
    end

    it 'grants a multiple users the superadmin role' do
      run_task('hyku:superadmin:grant', user1.email, user2.email)
      expect(user1.has_role?(:superadmin)).to eq true
      expect(user2.has_role?(:superadmin)).to eq true
    end
  end

  describe 'tenantize:task' do
    # Creating full-fledged accounts because switching into a factory
    # account leads to: One of the following schema(s) is invalid:
    # "3af179cd-d433-43ab-9a53-23c38750cf45" "public"
    # This is expensive.
    before(:all) do
      CreateAccount.new(Account.new(name: 'first')).save
      CreateAccount.new(Account.new(name: 'second')).save
    end

    after(:all) do
      Account.find_by(name: 'first').destroy
      Account.find_by(name: 'second').destroy
    end

    before do
      # This omits a tenant that appears automatically created and is not switch-intoable
      allow(Account).to receive(:tenants).and_return(accounts)
    end

    let(:accounts) { Account.where(name: ['first', 'second']) }
    let(:task) { double('task') }

    it 'requires at least one argument' do
      expect { run_task('tenantize:task') }.to raise_error(ArgumentError, /rake task name is required/)
    end
    it 'requires first argument to be a valid rake task' do
      expect { run_task('tenantize:task', 'foobar') }.to raise_error(ArgumentError, /Rake task not found\: foobar/)
    end
    it 'runs against all tenants' do
      accounts.each do |account|
        expect(account).to receive(:switch).once.and_call_original
      end
      allow(Rake::Task).to receive(:[]).with('hyrax:count').and_return(task)
      expect(task).to receive(:invoke).exactly(accounts.count).times
      expect(task).to receive(:reenable).exactly(accounts.count).times
      run_task('tenantize:task', 'hyrax:count')
    end
    context 'when run against specified tenants' do
      let(:accounts) { [account] }
      let(:account) { Account.find_by(name: 'first') }

      before do
        ENV['tenants'] = "garbage_value #{account.cname} other_garbage_value"
      end

      after do
        ENV.delete('tenants')
      end

      it 'runs against a single tenant and ignores bogus tenants' do
        expect(account).to receive(:switch).once.and_call_original
        allow(Rake::Task).to receive(:[]).with('hyrax:count').and_return(task)
        expect(task).to receive(:invoke).once
        expect(task).to receive(:reenable).once
        run_task('tenantize:task', 'hyrax:count')
      end
    end
  end
end
