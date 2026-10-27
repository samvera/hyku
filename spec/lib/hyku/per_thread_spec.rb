# frozen_string_literal: true

RSpec.describe Hyku::PerThread do
  after { ActiveSupport::IsolatedExecutionState.delete(described_class::STATE_KEY) }

  describe '.attribute' do
    let(:owner_class) do
      Class.new do
        attr_writer :name, :options
        def name
          @name ||= 'boot'
        end

        def options
          @options ||= { host: 'boot.example' }
        end
      end
    end
    let(:owner) { owner_class.new }

    before do
      described_class.attribute(owner_class, :name)
      described_class.attribute(owner_class, :options, copy: true)
    end

    it 'writes through until the thread switches tenants' do
      Thread.new { owner.name = 'set at boot' }.join

      expect(owner.name).to eq('set at boot')
    end

    it "keeps a switched thread's writes to itself" do
      described_class.reset!
      owner.name = 'tenant a'

      expect(owner.name).to eq('tenant a')
      expect(Thread.new { owner.name }.value).to eq('boot')
    end

    it 'falls back to the boot value after a reset' do
      described_class.reset!
      owner.name = 'tenant a'
      described_class.reset!

      expect(owner.name).to eq('boot')
    end

    it "reads the reader's default when the stored value is falsy" do
      described_class.attribute(owner_class, :flag, readers: %i[flag?], falsy_falls_back: true)
      owner_class.class_eval do
        attr_writer :flag
        def flag?
          @flag ||= 'default'
        end
      end
      owner.flag = 'set at boot'
      described_class.reset!
      owner.flag = false

      expect(owner.flag?).to eq('default')
    end

    it 'gives each thread its own copy of a value mutated in place' do
      described_class.reset!
      owner.options[:host] = 'tenant-a.example'

      expect(owner.options[:host]).to eq('tenant-a.example')
      expect(Thread.new { owner.options[:host] }.value).to eq('boot.example')
    end

    it 'wraps an attribute only once when registered again' do
      expect { described_class.attribute(owner_class, :name) }.not_to(change { owner_class.ancestors.size })
    end

    it 'wraps more readers of an attribute that is already registered' do
      owner_class.define_method(:name?) { name.present? }
      described_class.attribute(owner_class, :name, readers: %i[name?], falsy_falls_back: true)
      described_class.reset!
      owner.name = 'tenant a'

      expect(owner.name?).to eq('tenant a')
    end
  end

  describe '.attribute on a class' do
    let(:base_class) { Class.new { class_attribute :store, default: 'boot' } }
    let(:subclass) { Class.new(base_class) }

    before { described_class.attribute(base_class.singleton_class, :store) }

    it "gives subclasses the switched thread's value" do
      described_class.reset!
      base_class.store = 'tenant a'

      expect(subclass.store).to eq('tenant a')
    end

    it 'lets a subclass keep a value it sets on itself' do
      described_class.reset!
      subclass.store = 'own'

      expect(subclass.store).to eq('own')
      expect(base_class.store).to eq('boot')
    end
  end

  context 'across concurrent tenant switches' do
    let(:account_a) { FactoryBot.build(:sign_up_account) }
    let(:account_b) { FactoryBot.build(:sign_up_account) }

    before { [account_a, account_b].each { |account| CreateAccount.new(account, []).save } }

    after { Apartment::Tenant.switch!(Apartment.default_tenant) }

    # A thread's DB connection can't see rows inside the main thread's open transaction.
    it "keeps each tenant's URL host", truncation: true do
      results = results_per_tenant([account_a, account_b]) do
        [Rails.application.routes.default_url_options[:host], Hyrax::Engine.routes.default_url_options[:host]]
      end

      expect(results).to eq(account_a => [[account_a.cname] * 2], account_b => [[account_b.cname] * 2])
    end
  end
end
