# frozen_string_literal: true

RSpec.describe Hyrax::CollectionTypes::CreateService, type: :decorator do
  let(:added_participants) do
    {
      agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
      agent_id: 'collection_manager',
      access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
    }
  end

  describe '.add_default_participants' do
    it 'is overridden by our decorator' do
      expect(described_class.method(:add_default_participants).source_location.first).to end_with('create_service_decorator.rb')
    end
  end

  describe 'DEFAULT_OPTIONS' do
    it 'is overridden by our decorator' do
      expect(Hyrax::CollectionTypes::CreateService::DEFAULT_OPTIONS[:participants]).to include(added_participants)
    end
  end

  describe 'USER_COLLECTION_OPTIONS' do
    it 'is overridden by our decorator' do
      expect(Hyrax::CollectionTypes::CreateService::USER_COLLECTION_OPTIONS[:participants]).to include(added_participants)
    end
  end
end
