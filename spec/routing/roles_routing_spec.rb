# frozen_string_literal: true

RSpec.describe RolesController, type: :routing do
  describe "routing" do
    it "routes to #edit" do
      expect(get: "/site/roles").to route_to("roles#index")
    end
    it "routes to #update via PUT" do
      expect(put: "/site/roles/1").to route_to("roles#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/site/roles/1").to route_to("roles#update", id: "1")
    end
  end
end
