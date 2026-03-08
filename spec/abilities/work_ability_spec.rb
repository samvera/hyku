# frozen_string_literal: true

require 'cancan/matchers'

# rubocop:disable RSpec/FilePath
RSpec.describe Hyrax::Ability::WorkAbility do
  # rubocop:enable RSpec/FilePath
  subject(:ability) { ::Ability.new(user) }

  let(:user) { FactoryBot.create(:user) }

  VALKYRIE_FACTORY_MAP = {
    'GenericWork' => :generic_work_resource,
    'Image' => :image_resource,
    'Etd' => :etd_resource,
    'Oer' => :oer_resource,
    'FileSet' => :hyrax_file_set
  }.freeze

  context 'when work editor' do
    before do
      FactoryBot.create(:editors_group, member_users: [user])
    end

    (Hyrax.config.curation_concerns + [::FileSet]).each do |model|
      context "#{model} permissions" do
        let(:factory_name) { VALKYRIE_FACTORY_MAP[model.to_s] || model.to_s.underscore.to_sym }
        let(:model_instance) { FactoryBot.valkyrie_create(factory_name, title: ["#{model} instance"]) }
        let(:solr_doc) do
          doc = Hyrax::ValkyrieIndexer.for(resource: model_instance).to_solr
          ::SolrDocument.new(doc.merge('title_tesim' => ["#{model} solr doc"]))
        end
        let(:id) { model_instance.id.to_s }

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

    (Hyrax.config.curation_concerns + [::FileSet]).each do |model|
      context "#{model} permissions" do
        let(:factory_name) { VALKYRIE_FACTORY_MAP[model.to_s] || model.to_s.underscore.to_sym }
        let(:model_instance) { FactoryBot.valkyrie_create(factory_name, title: ["#{model} instance"]) }
        let(:solr_doc) do
          doc = Hyrax::ValkyrieIndexer.for(resource: model_instance).to_solr
          ::SolrDocument.new(doc.merge('title_tesim' => ["#{model} solr doc"]))
        end
        let(:id) { model_instance.id.to_s }

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
