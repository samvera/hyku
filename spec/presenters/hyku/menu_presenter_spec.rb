require 'rails_helper'

RSpec.describe Hyku::MenuPresenter do
  let(:instance) { described_class.new(context) }
  let(:context) { double }
  let(:controller_name) { controller.controller_name }

  describe "#repository_activity_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end
    subject { instance.repository_activity_section? }

    context "for the ContentBlocksController" do
      let(:controller) { ContentBlocksController.new }
      it { is_expected.to be false }
    end
    context "for the StatusController" do
      let(:controller) { StatusController.new }
      it { is_expected.to be true }
    end
  end

  describe "#user_activity_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end
    subject { instance.user_activity_section? }
    context "for the Hyrax::UsersController" do
      let(:controller) { Hyrax::UsersController.new }
      it { is_expected.to be true }
    end
    context "for the Admin::UsersController" do
      let(:controller) { Admin::UsersController.new }
      it { is_expected.to be false }
    end
  end

  describe "#settings_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end
    subject { instance.settings_section? }
    context "for the ContentBlocksController" do
      let(:controller) { ContentBlocksController.new }
      it { is_expected.to be true }
    end
    context "for the Admin::UsersController" do
      let(:controller) { Admin::UsersController.new }
      it { is_expected.to be false }
    end
  end

  describe "#workflows_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end
    subject { instance.workflows_section? }
    context "for the WorkflowRolesController" do
      let(:controller) { Hyrax::Admin::WorkflowRolesController.new }
      it { is_expected.to be true }
    end
    context "for the Admin::UsersController" do
      let(:controller) { Admin::UsersController.new }
      it { is_expected.to be false }
    end
  end

  describe "#roles_and_permissions_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end
    subject { instance.roles_and_permissions_section? }
    context "for the Hyrax::UsersController" do
      let(:controller) { Hyrax::UsersController.new }

      it { is_expected.to be false }
    end
    context "for the Admin::UsersController" do
      let(:controller) { Admin::UsersController.new }
      it { is_expected.to be true }
    end
  end
end
