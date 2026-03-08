# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax do
  describe '.config' do
    subject { described_class.config }

    # We're noticing behavior regarding factories that generate the wrong configured classes.
    # This spec is here to provide a similar type test.
    its(:admin_set_class) { is_expected.to eq(AdminSetResource) }
    its(:collection_class) { is_expected.to eq(CollectionResource) }

    it 'aligns disable_wings with env override or transition mode' do
      expected_disable_wings = if ENV.key?('DISABLE_WINGS')
                                 ActiveModel::Type::Boolean.new.cast(ENV['DISABLE_WINGS'])
                               else
                                 !subject.valkyrie_transition?
                               end
      expect(subject.disable_wings).to eq(expected_disable_wings)
    end

    it 'removes wings query service when disable_wings is true' do
      skip 'Only applies when Wings is disabled' unless subject.disable_wings
      expect(Hyrax.query_service).to be_a(Valkyrie::Persistence::Postgres::QueryService)
    end

    it 'keeps parent work custom query available when wings disabled' do
      skip 'Only applies when Wings is disabled' unless subject.disable_wings
      expect(Hyrax.custom_queries).to respond_to(:find_parent_work)
    end
  end
end
