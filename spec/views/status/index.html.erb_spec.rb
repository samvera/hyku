# frozen_string_literal: true

RSpec.describe "status/index", type: :view do
  let(:account) { create(:account) }

  context "when Wings is enabled" do
    before do
      allow(Hyrax.config).to receive(:disable_wings).and_return(false)
      allow(view).to receive(:current_account).and_return(account)
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
      render
    end

    it "renders a Fedora service row" do
      expect(rendered).to include("Fedora")
    end
  end

  context "when Wings is disabled" do
    before do
      allow(Hyrax.config).to receive(:disable_wings).and_return(true)
      allow(view).to receive(:current_account).and_return(account)
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
      render
    end

    it "does not render a Fedora service row" do
      expect(rendered).not_to include("Fedora")
    end

    it "renders Solr, Redis, and Database status rows" do
      expect(rendered).to include("Solr")
      expect(rendered).to include("Redis")
      expect(rendered).to include("Database")
    end
  end
end
