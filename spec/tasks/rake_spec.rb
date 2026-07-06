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
    let(:accounts) { [Account.new(name: 'first'), Account.new(name: 'second')] }
    let(:task) { double('task') }

    before do
      # This omits a tenant that appears automatically created and is not switch-intoable
      allow(Account).to receive(:tenants).and_return(accounts)
    end

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
      let(:account) { accounts[0] }

      before do
        ENV['tenants'] = "garbage_value #{account.cname} other_garbage_value"
        allow(Account).to receive(:tenants).with(ENV['tenants'].split).and_return([account])
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

  describe 'db:seed:sample:create' do
    let(:valkyrie_service) { instance_double(Sample::ValkyrieService, create_sample_data: true) }
    let(:af_service) { instance_double(Sample::ActiveFedoraService, create_sample_data: true) }

    it 'passes tenant, quantity, and visibility through to the valkyrie service' do
      expect(Sample::ValkyrieService).to receive(:new).with('demo', '10', 'open').and_return(valkyrie_service)
      run_task('db:seed:sample:create', 'demo', 'valkyrie', '10', 'open')
    end

    it 'passes visibility through to the active fedora service' do
      expect(Sample::ActiveFedoraService).to receive(:new).with('demo', '10', 'restricted').and_return(af_service)
      run_task('db:seed:sample:create', 'demo', 'af', '10', 'restricted')
    end

    it 'defaults to no visibility override' do
      expect(Sample::ValkyrieService).to receive(:new).with('demo', '10', nil).and_return(valkyrie_service)
      run_task('db:seed:sample:create', 'demo', 'valkyrie', '10')
    end

    it 'rejects an unrecognized visibility value' do
      expect(Sample::ValkyrieService).not_to receive(:new)
      expect(run_task('db:seed:sample:create', 'demo', 'valkyrie', '10', 'public')).to include('ERROR')
    end
  end
end
