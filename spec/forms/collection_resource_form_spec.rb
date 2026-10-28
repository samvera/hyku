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
        expect(change_set.respond_to?(:hide_from_catalog_search)).to be true
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
        expect(change_set.respond_to?(:hide_from_catalog_search)).to be true
        expect(change_set.respond_to?(:hide_from_catalog_search=)).to be true
      end

      it 'can be set the value to true when the box is checked' do
        change_set.hide_from_catalog_search = true
        expect(change_set.hide_from_catalog_search).to be true
      end

      it 'can be set the value to false when the box is unchecked' do
        change_set.hide_from_catalog_search = false
        expect(change_set.hide_from_catalog_search).to be false
      end

      # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
      # expected true, got "1".
      it 'converts string "1" to true (checkbox checked)', flexible: false do
        change_set.hide_from_catalog_search = "1"
        expect(change_set.hide_from_catalog_search).to eq(true)
      end

      # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
      # expected false, got "0".
      it 'converts string "0" to false (checkbox unchecked)', flexible: false do
        change_set.hide_from_catalog_search = "0"
        expect(change_set.hide_from_catalog_search).to eq(false)
      end

      # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
      # expected true, got "true".
      it 'converts string "true" to true (checkbox checked)', flexible: false do
        change_set.hide_from_catalog_search = "true"
        expect(change_set.hide_from_catalog_search).to eq(true)
      end

      # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
      # expected false, got "false".
      it 'converts string "false" to false (checkbox unchecked)', flexible: false do
        change_set.hide_from_catalog_search = "false"
        expect(change_set.hide_from_catalog_search).to eq(false)
      end
    end
  end
end
