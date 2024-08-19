# frozen_string_literal: true

require 'cancan/matchers'

# rubocop:disable RSpec/FilePath
RSpec.describe Hyrax::Ability::WorkAbility do
  # rubocop:enable RSpec/FilePath
  subject(:ability) { ::Ability.new(user) }

  let(:user) { FactoryBot.create(:user) }

  context 'when work editor' do
    before do
      FactoryBot.create(:editors_group, member_users: [user])
    end

    # TODO: We need to create factories for GenericWorkResource and ImageResource.
    # NOTE: This assumes that all curation_conerns are ActiveFedora based.
    # FactoryBot.create is for ActiveFedora models.  And
    # FactoryBot.valkyrie_create is for Valkyrie models.
    (Hyrax.config.curation_concerns + [::FileSet]).each do |model|
      context "#{model} permissions" do
        let(:model_instance) { FactoryBot.create(model.to_s.underscore.to_sym, title: ["#{model} instance"]) }
        let(:solr_doc) { ::SolrDocument.new(model_instance.to_solr.merge('title_tesim' => ["#{model} solr doc"])) }
        let(:id) { model_instance.id }

        it { is_expected.to be_able_to(:create, model) }

        it { is_expected.to be_able_to(:read, model_instance) }
        it { is_expected.to be_able_to(:read, solr_doc) }
        it { is_expected.to be_able_to(:read, id) }

        it { is_expected.to be_able_to(:edit, model_instance) }
        it { is_expected.to be_able_to(:edit, solr_doc) }
        it { is_expected.to be_able_to(:edit, id) }

        it { is_expected.to be_able_to(:update, model_instance) }
        it { is_expected.to be_able_to(:update, solr_doc) }
        it { is_expected.to be_able_to(:update, id) }

        it { is_expected.not_to be_able_to(:destroy, model_instance) }
        it { is_expected.not_to be_able_to(:destroy, solr_doc) }
        it { is_expected.not_to be_able_to(:destroy, id) }
      end
    end
  end

  context 'when work depositor' do
    before do
      FactoryBot.create(:depositors_group, member_users: [user])
    end

    # NOTE: This assumes that all curation_conerns are ActiveFedora based.
    # FactoryBot.create is for ActiveFedora models.  And
    # FactoryBot.valkyrie_create is for Valkyrie models.
    (Hyrax.config.curation_concerns + [::FileSet]).each do |model|
      context "#{model} permissions" do
        let(:model_instance) { FactoryBot.create(model.to_s.underscore.to_sym, title: ["#{model} instance"]) }
        let(:solr_doc) { ::SolrDocument.new(model_instance.to_solr.merge('title_tesim' => ["#{model} solr doc"])) }
        let(:id) { model_instance.id }

        it { is_expected.to be_able_to(:create, model) }

        it { is_expected.not_to be_able_to(:read, model_instance) }
        it { is_expected.not_to be_able_to(:read, solr_doc) }
        it { is_expected.not_to be_able_to(:read, id) }

        it { is_expected.not_to be_able_to(:edit, model_instance) }
        it { is_expected.not_to be_able_to(:edit, solr_doc) }
        it { is_expected.not_to be_able_to(:edit, id) }

        it { is_expected.not_to be_able_to(:update, model_instance) }
        it { is_expected.not_to be_able_to(:update, solr_doc) }
        it { is_expected.not_to be_able_to(:update, id) }

        it { is_expected.not_to be_able_to(:destroy, model_instance) }
        it { is_expected.not_to be_able_to(:destroy, solr_doc) }
        it { is_expected.not_to be_able_to(:destroy, id) }
      end
    end
  end
end
