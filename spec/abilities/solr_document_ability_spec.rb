# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Add tests covering Groups with Roles permissions
require 'cancan/matchers'

# rubocop:disable RSpec/FilePath
RSpec.describe Hyrax::Ability::SolrDocumentAbility do
  # rubocop:enable RSpec/FilePath
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }

  # OVERRIDE: add specs for custom ability logic
  context 'with Collection solr doc' do
    let(:collection_type_gid) { create(:collection_type).to_global_id }
    let(:collection) do
      FactoryBot.create(:hyku_collection,
        with_permission_template: true,
        collection_type_gid:)
    end
    let!(:solr_document) { SolrDocument.new(collection.to_solr) }

    context 'when admin user' do
      let(:user) { FactoryBot.create(:admin) }

      it 'allows all abilities' do
        is_expected.to be_able_to(:manage, SolrDocument)
        is_expected.to be_able_to(:manage_any, SolrDocument)
        is_expected.to be_able_to(:create_any, SolrDocument)
        is_expected.to be_able_to(:view_admin_show_any, SolrDocument)
        is_expected.to be_able_to(:edit, solr_document)
        is_expected.to be_able_to(:update, solr_document)
        is_expected.to be_able_to(:destroy, solr_document)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, solr_document)
      end
    end

    context 'when a user has a Collections Manager role' do
      let(:user) { FactoryBot.create(:collection_manager) }

      it 'allows all abilities' do
        is_expected.to be_able_to(:manage, SolrDocument)
        is_expected.to be_able_to(:manage_any, SolrDocument)
        is_expected.to be_able_to(:create_any, SolrDocument)
        is_expected.to be_able_to(:view_admin_show_any, SolrDocument)
        is_expected.to be_able_to(:edit, solr_document)
        is_expected.to be_able_to(:update, solr_document)
        is_expected.to be_able_to(:destroy, solr_document)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, solr_document)
      end
    end

    context 'when a user has a Collections Editor role' do
      let(:user) { FactoryBot.create(:collection_editor) }

      it 'allows most abilities' do
        is_expected.to be_able_to(:edit, solr_document)
        is_expected.to be_able_to(:update, solr_document)
        is_expected.to be_able_to(:read, solr_document)
        is_expected.to be_able_to(:view_admin_show, solr_document)
      end

      it 'denies destroy ability' do
        is_expected.not_to be_able_to(:destroy, solr_document)
      end
    end

    context 'when a user has a Collections Reader role' do
      let(:user) { FactoryBot.create(:collection_reader) }

      it 'allows read abilities' do
        is_expected.to be_able_to(:read_any, SolrDocument)
        is_expected.to be_able_to(:view_admin_show_any, SolrDocument)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, solr_document)
      end

      it 'denies most abilities' do
        is_expected.not_to be_able_to(:manage, SolrDocument)
        is_expected.not_to be_able_to(:create, SolrDocument)
        is_expected.not_to be_able_to(:edit, solr_document)
        is_expected.not_to be_able_to(:update, solr_document)
        is_expected.not_to be_able_to(:deposit, solr_document)
        is_expected.not_to be_able_to(:destroy, solr_document)
      end
    end
  end

  # rubocop:disable RSpec/EmptyExampleGroup
  context 'with admin_set' do
    # tested with admin_set's solr doc in admin_set_ability_spec.rb
  end

  context 'with works' do
    # tested with work's solr doc in work_ability_spec.rb
  end

  context 'with files' do
    # TODO: Need tests for files
  end
  # rubocop:enable RSpec/EmptyExampleGroup
end
