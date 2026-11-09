# frozen_string_literal: true

require 'rake'
load Rails.root.join('app', 'models', 'site.rb')

RSpec.describe "Rake tasks" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
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
    let(:accounts) do
      [Account.new(name: 'first', tenant: 'first-tenant'), Account.new(name: 'second', tenant: 'second-tenant')]
    end
    let(:task) { double('task', reenable: nil) }
    let(:invoked_in) { [] }

    before do
      # This omits a tenant that appears automatically created and is not switch-intoable
      allow(Account).to receive(:tenants).and_return(accounts)
      current_schema = 'public'
      allow(Apartment::Tenant).to receive(:switch) do |tenant, &block|
        current_schema = tenant
        block.call
      ensure
        current_schema = 'public'
      end
      allow(Rake::Task).to receive(:[]).and_call_original
      allow(Rake::Task).to receive(:[]).with('hyrax:count').and_return(task)
      allow(task).to receive(:invoke) { |*task_args| invoked_in << [current_schema, task_args] }
    end

    it 'requires at least one argument' do
      expect { run_task('tenantize:task') }.to raise_error(ArgumentError, /rake task name is required/)
    end

    it 'requires first argument to be a valid rake task' do
      expect { run_task('tenantize:task', 'foobar') }.to raise_error(ArgumentError, /Rake task not found\: foobar/)
    end

    it "runs the task inside each tenant's database schema, passing along the extra arguments" do
      run_task('tenantize:task', 'hyrax:count', 'extra-arg')

      expect(invoked_in).to eq [['first-tenant', ['extra-arg']], ['second-tenant', ['extra-arg']]]
    end

    it 're-enables the task before each run so it runs for every tenant' do
      expect(task).to receive(:reenable).ordered
      expect(task).to receive(:invoke).ordered
      expect(task).to receive(:reenable).ordered
      expect(task).to receive(:invoke).ordered

      run_task('tenantize:task', 'hyrax:count')
    end

    it 'skips search-only accounts' do
      search_only = Account.new(name: 'cross', tenant: 'cross-tenant', search_only: true)
      allow(Account).to receive(:tenants).and_return(accounts + [search_only])

      run_task('tenantize:task', 'hyrax:count')

      expect(invoked_in.map(&:first)).to eq %w[first-tenant second-tenant]
    end

    context 'when run against specified tenants' do
      let(:account) { accounts[0] }

      before do
        ENV['tenants'] = "garbage_value #{account.cname} other_garbage_value"
        allow(Account).to receive(:tenants).with(ENV['tenants'].split).and_return([account])
      end

      after do
        ENV.delete('tenants')
      end

      it 'runs against a single tenant and ignores bogus tenants' do
        run_task('tenantize:task', 'hyrax:count')

        expect(invoked_in.map(&:first)).to eq ['first-tenant']
      end
    end
  end

  describe 'hyku:demo:snapshot' do
    it 'requires a tenant argument' do
      expect { run_task('hyku:demo:snapshot') }.to raise_error(ArgumentError)
    end

    it 'raises for an unknown tenant' do
      expect { run_task('hyku:demo:snapshot', 'not-a-tenant') }
        .to raise_error(ArgumentError, /No account/)
    end

    it 'captures a snapshot for the named demo tenant without force by default' do
      account = FactoryBot.create(:demo_account)
      service = instance_double(DemoTenantResetService, snapshot!: true)
      allow(DemoTenantResetService).to receive(:new).with(account:).and_return(service)
      run_task('hyku:demo:snapshot', account.cname)
      expect(service).to have_received(:snapshot!).with(force: false)
    end

    it 'passes force: true when FORCE=1' do
      account = FactoryBot.create(:demo_account)
      service = instance_double(DemoTenantResetService, snapshot!: true)
      allow(DemoTenantResetService).to receive(:new).with(account:).and_return(service)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FORCE').and_return('1')
      run_task('hyku:demo:snapshot', account.cname)
      expect(service).to have_received(:snapshot!).with(force: true)
    end
  end

  describe 'hyku:demo:reset' do
    it 'requires a tenant argument' do
      expect { run_task('hyku:demo:reset') }.to raise_error(ArgumentError)
    end

    it 'raises for an unknown tenant' do
      expect { run_task('hyku:demo:reset', 'not-a-tenant') }
        .to raise_error(ArgumentError, /No account/)
    end

    it 'refuses to reset an account that is not a public demo tenant' do
      account = FactoryBot.create(:account)
      expect { run_task('hyku:demo:reset', account.cname) }
        .to raise_error(DemoTenantResetService::NotDemoTenant)
    end

    it 'resets the named demo tenant' do
      account = FactoryBot.create(:demo_account)
      service = instance_double(DemoTenantResetService, reset!: true)
      allow(DemoTenantResetService).to receive(:new).and_return(service)
      run_task('hyku:demo:reset', account.cname)
      expect(service).to have_received(:reset!)
    end
  end
end
