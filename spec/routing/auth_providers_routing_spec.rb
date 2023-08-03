require "rails_helper"

RSpec.describe AuthProvidersController, type: :routing do
  describe "routing" do
    it "routes to #new" do
      expect(get: "/auth_providers/new").to route_to("auth_providers#new")
    end

    it "routes to #edit" do
      expect(get: "/auth_providers/1/edit").to route_to("auth_providers#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/auth_providers").to route_to("auth_providers#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/auth_providers/1").to route_to("auth_providers#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/auth_providers/1").to route_to("auth_providers#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/auth_providers/1").to route_to("auth_providers#destroy", id: "1")
    end
  end
end
