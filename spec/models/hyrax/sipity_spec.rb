# frozen_string_literal: true
# OVERRIDE: Hyrax 5.0.x to add an additional spec to test the Sipity.Entity conversions with migration
# This can be removed once code is ported back to Hyrax
RSpec.describe Sipity do
  describe '.Entity' do
    let(:user) { create(:user) }
    let(:workflow_state) { FactoryBot.create(:workflow_state) }
    let(:work) { create(:generic_work, user: user) }
    let(:solr_document) { SolrDocument.new(id: work.id, has_model_ssim: ["GenericWork"]) }
    # rubocop:disable Lint/RedundantStringCoercion
    # Use Hyrax::GlobalID as it handles both AF and Valkyrie objects
    let(:proxy_string) { Hyrax::GlobalID(work).to_s }
    # rubocop:enable Lint/RedundantStringCoercion

    context 'on a generic work with lazy migration: true' do
      before do
        skip 'Requires Wings/ActiveFedora' if Hyrax.config.disable_wings
        with_disable_wings(false)
      end

      it 'will find the entity' do
        with_valkyrie_transition(true) do
          model = solr_document.to_model
          saved_entity = Sipity::Entity.create(
            proxy_for_global_id: model.to_global_id.to_s,
            workflow_state: workflow_state,
            workflow: workflow_state.workflow
          )
          subject = described_class.Entity(solr_document)
          expect(subject).to eq(saved_entity)
        end
      end
    end

    context 'on a generic work with lazy migration: false' do
      before do
        skip 'Requires Wings/ActiveFedora' if Hyrax.config.disable_wings
        with_disable_wings(false)
      end

      it 'will find the entity' do
        with_valkyrie_transition(false) do
          saved_entity = Sipity::Entity.create(
            proxy_for_global_id: proxy_string,
            workflow_state: workflow_state,
            workflow: workflow_state.workflow
          )
          subject = described_class.Entity(solr_document)
          expect(subject).to eq(saved_entity)
        end
      end
    end

    context 'on a solr document with transition false and wings disabled' do
      let(:solr_document) { SolrDocument.new(id: 'test-no-fcrepo-id', has_model_ssim: ["GenericWork"]) }

      it 'resolves via query_service and avoids to_model' do
        with_valkyrie_transition(false) do
          proxy_string = 'gid://hyku/GenericWork/test-no-fcrepo-id'
          global_id = URI::GID.parse(proxy_string)
          query_resource = instance_double('QueryResource', id: solr_document.id, to_global_id: global_id)

          with_disable_wings(true) do
            allow(Hyrax.query_service).to receive(:find_by).with(id: solr_document.id).and_return(query_resource)
            expect(solr_document).not_to receive(:to_model)

            saved_entity = Sipity::Entity.create(
              proxy_for_global_id: proxy_string,
              workflow_state: workflow_state,
              workflow: workflow_state.workflow
            )

            subject = described_class.Entity(solr_document)
            expect(subject).to eq(saved_entity)
          end
        end
      end
    end
  end
end
