# frozen_string_literal: true

RSpec.describe AppIndexer do
  subject(:solr_document) { service.generate_solr_document }

  let(:service) { described_class.new(work) }
  let(:work) { create(:work) }

  context "account_cname_tesim" do
    let(:account) { create(:account, cname: 'hyky-test.me') }

    before do
      allow(Apartment::Tenant).to receive(:switch!).with(account.tenant) do |&block|
        block&.call
      end

      Apartment::Tenant.switch!(account.tenant) do
        Site.update(account:)
        work
      end
    end

    it "indexer has the account_cname" do
      expect(solr_document.fetch("account_cname_tesim")).to eq(account.cname)
    end
  end

  describe "#generate_solr_document" do
    context "when given a date with a YYYY-MM-DD format" do
      it "indexes date_ssi in YYYY-MM-DD format" do
        work.date_created = ["2024-01-01"]
        expect(solr_document.fetch("date_ssi")).to eq("2024-01-01")
      end
    end

    context "when given a date with a YYYY-MM format" do
      it "indexes date_ssi in YYYY-MM format" do
        work.date_created = ["2024-01"]
        expect(solr_document.fetch("date_ssi")).to eq("2024-01")
      end
    end

    context "when given a date with a YYYY format" do
      it "indexes date_ssi in YYYY format" do
        work.date_created = ["2024"]
        expect(solr_document.fetch("date_ssi")).to eq("2024")
      end
    end

    context "when given a date with a YYYY-M-D format" do
      it "converts the date to YYYY-MM-DD format and indexes date_ssi" do
        work.date_created = ["2024-1-1"]
        expect(solr_document.fetch("date_ssi")).to eq("2024-01-01")
      end
    end

    context "when given a date with a YYYY-M format" do
      it "converts the date to YYYY-MM format and indexes date_ssi" do
        work.date_created = ["2024-1"]
        expect(solr_document.fetch("date_ssi")).to eq("2024-01")
      end
    end

    context "when given a date with a YYYY-MM-D format" do
      it "converts the date to YYYY-MM-DD format and indexes date_ssi" do
        work.date_created = ["2024-01-1"]
        expect(solr_document.fetch("date_ssi")).to eq("2024-01-01")
      end
    end

    context "when given a date with a YYYY-M-DD format" do
      it "converts the date to YYYY-M-DD format and indexes date_ssi" do
        work.date_created = ["2024-1-01"]
        expect(solr_document.fetch("date_ssi")).to eq("2024-01-01")
      end
    end

    context "when given a date with an invalid format" do
      it "indexes the given date" do
        work.date_created = ["Jan 1, 2024"]
        expect(solr_document.fetch("date_ssi")).to eq("Jan 1, 2024")
      end
    end
  end
end
