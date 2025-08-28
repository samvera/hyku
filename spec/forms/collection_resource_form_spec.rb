# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe CollectionResourceForm do
  # Valkyrie resource model
  let(:resource)   { CollectionResource.new }
  # CollectionResourceForm class
  let(:change_set) { described_class.new(resource:) }

  it_behaves_like 'a Valkyrie::ChangeSet'

  describe 'hide_from_catalog_search' do
    context 'Valkyrie resource model' do
      # hide_from_catalog_search is an attribute in the collection_resource.yaml
      it 'is an attribute on the resource' do
        resource.respond_to?(:hide_from_catalog_search)
      end

      it 'defaults as nil' do
        expect(resource.hide_from_catalog_search).to be nil
      end

      it 'can be set to a boolean value' do
        resource.hide_from_catalog_search = true
        expect(resource.hide_from_catalog_search).to be true

        resource.hide_from_catalog_search = false
        expect(resource.hide_from_catalog_search).to be false
      end
    end

    context 'change_set form' do
      it 'can get and set values' do
        change_set.respond_to?(:hide_from_catalog_search)
        change_set.respond_to?(:hide_from_catalog_search=)
      end

      it 'can be set the value to true when the box is checked' do
        change_set.hide_from_catalog_search = true
        expect(change_set.hide_from_catalog_search).to be true
      end

      it 'can be set the value to false when the box is unchecked' do
        change_set.hide_from_catalog_search = false
        expect(change_set.hide_from_catalog_search).to be false
      end
    end
  end
end
