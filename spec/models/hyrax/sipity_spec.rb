# frozen_string_literal: true

# OVERRIDE: Hyrax 5.0.x to add an additional spec to test the Sipity.Entity conversions with migration
# This can be removed once code is ported back to Hyrax
RSpec.describe Sipity do
  describe '.Entity' do
    let(:subject) { described_class.Entity(solr_document) }

    let(:user) { create(:user) }
    let(:workflow_state) { FactoryBot.create(:workflow_state) }
    let(:solr_document) { SolrDocument.new(id: work.id, has_model_ssim: ["GenericWork"]) }
    # rubocop:disable Lint/RedundantStringCoercion
    # Use Hyrax::GlobalID as it handles both AF and Valkyrie objects
    let(:proxy_string) { Hyrax::GlobalID(work).to_s }
    # rubocop:enable Lint/RedundantStringCoercion
    let(:saved_entity) do
      Sipity::Entity.create(proxy_for_global_id: proxy_string,
                            workflow_state: workflow_state,
                            workflow: workflow_state.workflow)
    end
    let(:work_resource) { Hyrax.query_service.find_by(id: work.id) }
    let(:migrated_entity) { Sipity::Entity.find_by(id: saved_entity.id) }

    context 'on a generic work with lazy migration: true' do
      let(:work) { create(:generic_work, user: user) }

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
        saved_entity
      end

      it 'will find the entity' do
        expect(subject).to eq(saved_entity)
      end
    end

    context 'on a generic work with lazy migration: false' do
      let(:work) { create(:generic_work, user: user) }

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
        saved_entity
      end

      it 'will find the entity' do
        expect(subject).to eq(saved_entity)
      end
    end
  end
end
