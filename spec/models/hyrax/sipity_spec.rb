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

    # NOTE: ideally this would create the entity with the original work and then migrate it.
    # However, the resulting entity ended up being the same (due to the adapters used in specs?)
    # so we had to fake the original entity.
    context 'with a migrated work' do
      let(:subject) { Sipity::Entity(migrated_work) }
      let(:work) { create(:generic_work, user: user) }
      # rubocop:disable Lint/RedundantStringCoercion
      let(:proxy_string) { "gid://hyku/this_will_be_wrong/#{work.id.to_s}" }
      # rubocop:enable Lint/RedundantStringCoercion
      let(:migrated_work) { Hyrax.query_service.find_by(id: work.id) }

      before do
        # we don't care if the work actually updated... just pretend it did so we can migrate the entity to what it should be
        allow_any_instance_of(Dry::Monads::Result::Failure).to receive(:success?).and_return(true)
        allow_any_instance_of(MigrateResourceServiceDecorator).to receive(:find_original_entity).and_return(saved_entity)
        MigrateResourceService.new(resource: work).call
      end

      it 'will find the migrated entity' do
        expect(subject).to eq(migrated_entity)
      end
    end

    context 'with a native Valkyrie work' do
      let(:work) { FactoryBot.valkyrie_create(:generic_work_resource) }

      before { saved_entity }

      it 'will find the entity' do
        expect(subject).to eq(saved_entity)
      end
    end
  end
end
