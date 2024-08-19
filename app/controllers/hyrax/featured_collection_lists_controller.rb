# frozen_string_literal: true

module Hyrax
  class FeaturedCollectionListsController < ApplicationController
    def create
      authorize! :update, FeaturedCollection
      FeaturedCollectionList.new.featured_collections_attributes = list_params[:featured_collections_attributes]
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { head :no_content }
      end
    end

    private

    def list_params
      params.require(:featured_collection_list).permit(featured_collections_attributes: %i[id order])
    end
  end
end
