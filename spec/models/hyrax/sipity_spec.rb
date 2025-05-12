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

    def with_valkyrie_transition_setting(value)
      original_value = Hyrax.config.valkyrie_transition?
      begin
        Hyrax.config.instance_variable_set(:@valkyrie_transition, value)
        yield
      ensure
        Hyrax.config.instance_variable_set(:@valkyrie_transition, original_value)
      end
    end

    context 'on a generic work with lazy migration: true' do
      it 'will find the entity' do
        with_valkyrie_transition_setting(true) do
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

    context 'on a generic work with lazy migration: false' do
      it 'will find the entity' do
        with_valkyrie_transition_setting(false) do
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
