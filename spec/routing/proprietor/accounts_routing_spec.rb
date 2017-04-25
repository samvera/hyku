RSpec.describe Proprietor::AccountsController, type: :routing do
  let(:admin_host) { Account.admin_host }
  let(:admin_host_url) { "http://#{admin_host}" }
  describe "routing" do
    it "routes to #index" do
      expect(get: "#{admin_host_url}/proprietor/accounts").to route_to("proprietor/accounts#index", host: admin_host)
    end

    it "routes to #new" do
      expect(get: "#{admin_host_url}/proprietor/accounts/new").to route_to("proprietor/accounts#new", host: admin_host)
    end

    it "routes to #show" do
      expect(get: "#{admin_host_url}/proprietor/accounts/1").to route_to("proprietor/accounts#show", id: "1", host: admin_host)
    end

    it "routes to #edit" do
      expect(get: "#{admin_host_url}/proprietor/accounts/1/edit").to route_to("proprietor/accounts#edit", id: "1", host: admin_host)
    end

    it "routes to #create" do
      expect(post: "#{admin_host_url}/proprietor/accounts").to route_to("proprietor/accounts#create", host: admin_host)
    end

    it "routes to #update via PUT" do
      expect(put: "#{admin_host_url}/proprietor/accounts/1").to route_to("proprietor/accounts#update", id: "1", host: admin_host)
    end

    it "routes to #update via PATCH" do
      expect(patch: "#{admin_host_url}/proprietor/accounts/1").to route_to("proprietor/accounts#update", id: "1", host: admin_host)
    end

    it "routes to #destroy" do
      expect(delete: "#{admin_host_url}/proprietor/accounts/1").to route_to("proprietor/accounts#destroy", id: "1", host: admin_host)
    end
  end
end
