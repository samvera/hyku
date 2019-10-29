require "rails_helper"

RSpec.describe Proprietor::UsersController, type: :routing do
  xdescribe "routing" do
    # skip these tests

    it "routes to #index" do
      expect(:get => "/proprietor/users").to route_to("proprietor/users#index")
    end

    it "routes to #new" do
      expect(:get => "/proprietor/users/new").to route_to("proprietor/users#new")
    end

    it "routes to #show" do
      expect(:get => "/proprietor/users/1").to route_to("proprietor/users#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/proprietor/users/1/edit").to route_to("proprietor/users#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/proprietor/users").to route_to("proprietor/users#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/proprietor/users/1").to route_to("proprietor/users#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/proprietor/users/1").to route_to("proprietor/users#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/proprietor/users/1").to route_to("proprietor/users#destroy", :id => "1")
    end

  end
end
