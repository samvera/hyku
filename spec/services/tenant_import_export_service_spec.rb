# frozen_string_literal: true

RSpec.describe TenantImportExportService do
  let(:account) { FactoryBot.build(:account) }

  before do
    create_account = CreateAccount.new(account)
    create_account.save
  end

  subject { described_class.new(account: account) }

  describe '#export' do
    it "exports the tenant's Site config and ContentBlock information" do
      expect(subject.export).to be_present

    end
  end

  describe '#import' do
    it "imports the tenant's Site config and ContentBlock information" do

    end
  end
end
