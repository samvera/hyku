# frozen_string_literal: true

require "rails_helper"

RSpec.describe Proprietor::UsersController, type: :routing do
  let(:admin_host) { Account.admin_host }
  let(:admin_host_url) { "http://#{admin_host}" }

  describe "routing" do
    it "routes to #index" do
      request = { get: "#{admin_host_url}/proprietor/users" }
      expect(request).to route_to("proprietor/users#index", host: admin_host)
    end

    it "routes to #new" do
      request = { get: "#{admin_host_url}/proprietor/users/new" }
      expect(request).to route_to("proprietor/users#new", host: admin_host)
    end

    it "routes to #show" do
      request = { get: "#{admin_host_url}/proprietor/users/1" }
      expect(request).to route_to("proprietor/users#show", id: "1", host: admin_host)
    end

    it "routes to #edit" do
      request = { get: "#{admin_host_url}/proprietor/users/1/edit" }
      expect(request).to route_to("proprietor/users#edit", id: "1", host: admin_host)
    end

    it "routes to #create" do
      request = { post: "#{admin_host_url}/proprietor/users" }
      expect(request).to route_to("proprietor/users#create", host: admin_host)
    end

    it "routes to #update via PUT" do
      request = { put: "#{admin_host_url}/proprietor/users/1" }
      expect(request).to route_to("proprietor/users#update", id: "1", host: admin_host)
    end

    it "routes to #update via PATCH" do
      request = { patch: "#{admin_host_url}/proprietor/users/1" }
      expect(request).to route_to("proprietor/users#update", id: "1", host: admin_host)
    end

    it "routes to #destroy" do
      request = { delete: "#{admin_host_url}/proprietor/users/1" }
      expect(request).to route_to("proprietor/users#destroy", id: "1", host: admin_host)
    end
  end
end
