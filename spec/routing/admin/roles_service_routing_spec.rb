# frozen_string_literal: true

RSpec.describe Admin::RolesServiceController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/admin/roles_service").to route_to("admin/roles_service#index")
    end

    it "routes to #update_roles via POST" do
      expect(post: "/admin/roles_service/create_collection_accesses")
        .to route_to("admin/roles_service#update_roles", job_name_key: 'create_collection_accesses')
    end
  end
end
