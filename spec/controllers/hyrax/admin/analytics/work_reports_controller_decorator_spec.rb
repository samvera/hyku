# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Admin::Analytics::WorkReportsController, type: :controller do
  routes { Hyrax::Engine.routes }

  describe "decorator" do
    let(:user) { create(:admin) }
    let(:work) { create(:generic_work, user: user) }
    let(:file_set) { create(:file_set, user: user) }

    before do
      # Set up real authentication
      sign_in user

      # Create real data that the controller will work with
      work
      file_set

      # Enable analytics reporting for the test
      allow(Hyrax.config).to receive(:analytics_reporting?).and_return(true)

      # Only mock the external analytics service to avoid real API calls
      allow(Hyrax::Analytics).to receive(:daily_events).and_return(Hyrax::Analytics::Results.new([]))
      allow(Hyrax::Analytics).to receive(:daily_events_for_id).and_return(Hyrax::Analytics::Results.new([]))
      allow(Hyrax::Analytics).to receive(:unique_visitors_for_id).and_return(Hyrax::Analytics::Results.new([]))
      allow(Hyrax::Analytics).to receive(:top_events).and_return([])
    end

    it "calls the analytics service with the correct tenant_id for work-view" do
      get :index
      expect(Hyrax::Analytics).to have_received(:daily_events)
        .with('work-view', tenant_id: 'FakeTenant')
    end

    it "calls the analytics service with the correct tenant_id for file-set-download" do
      get :index
      expect(Hyrax::Analytics).to have_received(:daily_events)
        .with('file-set-download', tenant_id: 'FakeTenant')
    end

    it "calls the analytics service with the correct tenant_id for show action" do
      get :show, params: { id: work.id }
      expect(Hyrax::Analytics).to have_received(:daily_events_for_id)
        .with(work.id, 'work-view', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
      expect(Hyrax::Analytics).to have_received(:unique_visitors_for_id)
        .with(work.id, Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
      expect(Hyrax::Analytics).to have_received(:daily_events_for_id)
        .with(work.id, 'file_set_in_work_download', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
    end

    it "only calls analytics when user is admin" do
      # Create a non-admin user
      non_admin_user = create(:user)
      sign_in non_admin_user

      get :index
      expect(Hyrax::Analytics).not_to have_received(:daily_events)
    end

    it "only calls analytics when analytics reporting is enabled" do
      allow(Hyrax.config).to receive(:analytics_reporting?).and_return(false)

      get :index
      expect(Hyrax::Analytics).not_to have_received(:daily_events)
    end
  end
end
