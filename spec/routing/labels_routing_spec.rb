# frozen_string_literal: true

RSpec.describe LabelsController, type: :routing do
  describe "routing" do
    it "routes to #edit" do
      expect(get: "/site/labels/edit").to route_to("labels#edit")
    end
    it "routes to #update via PUT" do
      expect(put: "/site/labels").to route_to("labels#update")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/site/labels").to route_to("labels#update")
    end
  end
end
