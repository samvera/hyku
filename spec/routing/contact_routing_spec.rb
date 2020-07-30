# frozen_string_literal: true

RSpec.describe ContactsController, type: :routing do
  describe "routing" do
    it "routes to #edit" do
      expect(get: "/site/contact/edit").to route_to("contacts#edit")
    end
    it "routes to #update via PUT" do
      expect(put: "/site/contact").to route_to("contacts#update")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/site/contact").to route_to("contacts#update")
    end
  end
end
