# frozen_string_literal: true

require 'hyrax/transactions'

RSpec.describe Hyku::Transactions::Steps::AddCustomRelations do
  subject(:step) { described_class.new }
  let(:change_set) { OerResourceForm.new(resource) }
  let(:resource) { valkyrie_create(:oer_resource) }
  let(:attributes) do
    { 'title' => ['Test OER'],
      'creator' => ['Foo'],
      'resource_type' => ['Article'],
      'date_created' => ['10/10/2020'],
      'audience' => ['Student'],
      'education_level' => ['Community college / Lower division'],
      'learning_resource_type' => ['Activity/lab'],
      'discipline' => ['Languages - Spanish'],
      'rights_statement' => 'http://rightsstatements.org/vocab/InC/1.0/',
      'related_members_attributes' => related_members_attributes }
  end
  let(:version_id) { 'abc123' }
  let(:related_members_attributes) do
    ActionController::Parameters.new(
      rand(10**14...10**15).to_s => { 'id' => version_id,
                                      '_destroy' => destroy,
                                      'relationship' => relationship }
    )
  end
  let(:destroy) { '' }
  let(:relationship) { '' }

  before do
    allow(change_set).to receive(:input_params).and_return(ActionController::Parameters.new(attributes))
  end

  describe '#call' do
    it 'is a success' do
      expect(step.call(change_set)).to be_success
    end

    context 'when adding the relationship' do
      let(:destroy) { 'false' }

      context 'previous version' do
        let(:relationship) { 'previous-version' }

        it 'adds the correct relationship' do
          expect(resource.previous_version_id).to eq([])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).previous_version_id).to eq([version_id])
        end
      end

      context 'newer version' do
        let(:relationship) { 'newer-version' }

        it 'adds the correct relationship' do
          expect(resource.newer_version_id).to eq([])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).newer_version_id).to eq([version_id])
        end
      end

      context 'alternate version' do
        let(:relationship) { 'alternate-version' }

        it 'adds the correct relationship' do
          expect(resource.alternate_version_id).to eq([])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).alternate_version_id).to eq([version_id])
        end
      end

      context 'related item' do
        let(:relationship) { 'related-item' }

        it 'adds the correct relationship' do
          expect(resource.related_item_id).to eq([])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).related_item_id).to eq([version_id])
        end
      end
    end

    context 'when removing the relationship' do
      let(:destroy) { 'true' }

      context 'previous version' do
        let(:relationship) { 'previous-version' }
        let(:resource) { valkyrie_create(:oer_resource, previous_version_id: [version_id]) }

        it 'adds the correct relationship' do
          expect(resource.previous_version_id).to eq([version_id])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).previous_version_id).to eq([])
        end
      end

      context 'newer version' do
        let(:relationship) { 'newer-version' }
        let(:resource) { valkyrie_create(:oer_resource, newer_version_id: [version_id]) }

        it 'adds the correct relationship' do
          expect(resource.newer_version_id).to eq([version_id])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).newer_version_id).to eq([])
        end
      end

      context 'alternate version' do
        let(:relationship) { 'alternate-version' }
        let(:resource) { valkyrie_create(:oer_resource, alternate_version_id: [version_id]) }

        it 'adds the correct relationship' do
          expect(resource.alternate_version_id).to eq([version_id])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).alternate_version_id).to eq([])
        end
      end

      context 'related item' do
        let(:relationship) { 'related-item' }
        let(:resource) { valkyrie_create(:oer_resource, related_item_id: [version_id]) }

        it 'adds the correct relationship' do
          expect(resource.related_item_id).to eq([version_id])
          step.call(change_set)

          expect(Hyrax.query_service.find_by(id: resource.id).related_item_id).to eq([])
        end
      end
    end
  end
end
