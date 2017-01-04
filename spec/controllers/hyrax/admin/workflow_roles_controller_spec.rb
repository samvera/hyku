require 'spec_helper'

RSpec.describe Hyrax::Admin::WorkflowRolesController, :no_clean do
  routes { Hyrax::Engine.routes }

  describe "#get overrides" do
    before do
      allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
    end

    it "loads workflows and renders with the admin layout" do
      expect(Hyrax::Workflow::WorkflowImporter).to receive(:load_workflows).once
      get :index
      expect(response).to render_template(layout: 'admin')
    end
  end
end
