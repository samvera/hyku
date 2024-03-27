# frozen_string_literal: true

RSpec.describe Hyrax::MenuPresenter do
  let(:instance) { described_class.new(context) }
  let(:context) { double }
  let(:controller_name) { controller.controller_name }

  describe "#repository_activity_section?" do
    subject { instance.repository_activity_section? }

    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end

    context "for the ContentBlocksController" do
      let(:controller) { Hyrax::ContentBlocksController.new }

      it { is_expected.to be false }
    end

    context "for the StatusController" do
      let(:controller) { StatusController.new }

      it { is_expected.to be true }
    end

    context "for the Hyrax::DashboardController" do
      let(:controller) { Hyrax::DashboardController.new }

      it { is_expected.to be true }
    end
  end

  describe "#settings_section?" do
    subject { instance.settings_section? }

    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end

    context "for the ContentBlocksController" do
      let(:controller) { Hyrax::ContentBlocksController.new }

      it { is_expected.to be true }
    end

    context "for the Admin::GroupsController" do
      let(:controller) { Admin::GroupsController.new }

      it { is_expected.to be false }
    end
  end

  describe "#roles_and_permissions_section?" do
    subject { instance.roles_and_permissions_section? }

    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end

    context "for the Hyrax::UsersController" do
      let(:controller) { Hyrax::UsersController.new }

      it { is_expected.to be false }
    end

    context "for the Hyrax::Admin::UsersController" do
      let(:controller) { Hyrax::Admin::UsersController.new }

      it { is_expected.to be true }
    end

    context "for the Admin::GroupsController" do
      let(:controller) { Admin::GroupsController.new }

      it { is_expected.to be true }
    end
  end

  describe "#show_configuration?" do
    subject { instance.show_configuration? }

    context "for a regular user" do
      before do
        allow(instance.view_context).to receive(:can?).and_return(false)
      end

      it { is_expected.to be false }
    end

    context "for a user who can manage users" do
      before do
        allow(instance.view_context).to receive(:can?).and_return(true)
      end

      it { is_expected.to be true }
    end
  end

  describe "#show_admin_menu_items?" do
    subject { instance.show_admin_menu_items? }

    context "for a regular user" do
      before do
        allow(instance.view_context).to receive(:can?).with(:read, :admin_dashboard).and_return(false)
      end

      it { is_expected.to be false }
    end

    context "for a user who can manage users" do
      before do
        allow(instance.view_context).to receive(:can?).with(:read, :admin_dashboard).and_return(true)
      end

      it { is_expected.to be true }
    end
  end

  describe "#collapsable_section" do
    let(:text) { "Sample Text" }
    let(:id) { "sample_id" }
    let(:icon_class) { "sample-icon-class" }
    let(:open) { true }
    let(:title) { "Cats" }
    let(:block) { proc { "<li>Item</li>" } }

    let(:presenter) { instance_double("CollapsableSectionPresenter") }

    before do
      allow(Hyrax::CollapsableSectionPresenter).to receive(:new).with(
        view_context: context,
        text:,
        id:,
        icon_class:,
        open:,
        title:
      ).and_return(presenter)
    end

    it "calls the render method on the CollapsableSectionPresenter with the given block" do
      expect(presenter).to receive(:render)
      instance.collapsable_section(text, id:, icon_class:, open:, title:, &block)
    end
  end
end
