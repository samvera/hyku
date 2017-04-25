RSpec.describe Admin::AccountsController, type: :routing do
  describe "routing" do
    it "routes to #edit" do
      expect(get: "/admin/account/edit").to route_to("admin/accounts#edit")
    end

    it "routes to #update via PUT" do
      expect(put: "/admin/account").to route_to("admin/accounts#update")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/admin/account").to route_to("admin/accounts#update")
    end
  end
end
