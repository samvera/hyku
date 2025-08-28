# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Admin::Analytics::CollectionReportsController, type: :controller do
  routes { Hyrax::Engine.routes }

  describe "decorator" do
    let(:user) { create(:admin) }
    let(:collection) { create(:collection, user: user) }
    let(:work) { create(:generic_work, user: user) }

    before do
      # Set up real authentication
      sign_in user

      # Create real data that the controller will work with
      collection
      work

      # Enable analytics reporting for the test
      allow(Hyrax.config).to receive(:analytics_reporting?).and_return(true)

      # Only mock the external analytics service to avoid real API calls
      allow(Hyrax::Analytics).to receive(:daily_events).and_return(Hyrax::Analytics::Results.new([]))
      allow(Hyrax::Analytics).to receive(:daily_events_for_id).and_return(Hyrax::Analytics::Results.new([]))
      allow(Hyrax::Analytics).to receive(:unique_visitors_for_id).and_return(Hyrax::Analytics::Results.new([]))
      allow(Hyrax::Analytics).to receive(:top_events).and_return([])
    end

    it "calls the analytics service with the correct tenant_id for collection-page-view" do
      get :index
      expect(Hyrax::Analytics).to have_received(:daily_events)
        .with('collection-page-view', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
    end

    it "calls the analytics service with the correct tenant_id for work-in-collection-view" do
      get :index
      expect(Hyrax::Analytics).to have_received(:daily_events)
        .with('work-in-collection-view', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
    end

    it "calls the analytics service with the correct tenant_id for work-in-collection-download" do
      get :index
      expect(Hyrax::Analytics).to have_received(:daily_events)
        .with('work-in-collection-download', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
    end

    it "calls top_events with the correct tenant_id for work-in-collection-view" do
      get :index
      expect(Hyrax::Analytics).to have_received(:top_events)
        .with('work-in-collection-view', anything, tenant_id: 'FakeTenant')
    end

    it "calls top_events with the correct tenant_id for work-in-collection-download" do
      get :index
      expect(Hyrax::Analytics).to have_received(:top_events)
        .with('work-in-collection-download', anything, tenant_id: 'FakeTenant')
    end

    it "calls top_events with the correct tenant_id for collection-page-view" do
      get :index
      expect(Hyrax::Analytics).to have_received(:top_events)
        .with('collection-page-view', anything, tenant_id: 'FakeTenant')
    end

    it "calls the analytics service with the correct tenant_id for show action" do
      get :show, params: { id: collection.id }
      expect(Hyrax::Analytics).to have_received(:daily_events_for_id)
        .with(collection.id, 'collection-page-view', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
      expect(Hyrax::Analytics).to have_received(:daily_events_for_id)
        .with(collection.id, 'work-in-collection-view', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
      expect(Hyrax::Analytics).to have_received(:unique_visitors_for_id)
        .with(collection.id, Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
      expect(Hyrax::Analytics).to have_received(:daily_events_for_id)
        .with(collection.id, 'work-in-collection-download', Hyrax::Analytics.default_date_range, tenant_id: 'FakeTenant')
    end

    it "only calls analytics when analytics reporting is enabled" do
      allow(Hyrax.config).to receive(:analytics_reporting?).and_return(false)

      get :index
      expect(Hyrax::Analytics).not_to have_received(:daily_events)
    end

    it "only calls analytics when analytics reporting is enabled for show action" do
      allow(Hyrax.config).to receive(:analytics_reporting?).and_return(false)

      get :show, params: { id: collection.id }
      expect(Hyrax::Analytics).not_to have_received(:daily_events_for_id)
    end
  end
end
