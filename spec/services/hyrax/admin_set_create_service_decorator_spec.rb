# frozen_string_literal: true

RSpec.describe Hyrax::AdminSetCreateServiceDecorator do
  describe '.find_unsaved_default_admin_set' do
    it 'does not query for legacy default admin set IDs when transition is disabled' do
      allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false)
      expect(Hyrax).not_to receive(:query_service)

      result = Hyrax::AdminSetCreateService.send(:find_unsaved_default_admin_set)

      expect(result).to be_nil
    end

    it 'queries legacy default admin set IDs when transition is enabled' do
      allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
      query_service = instance_double('QueryService')
      allow(Hyrax).to receive(:query_service).and_return(query_service)
      allow(query_service).to receive(:find_by).with(id: 'admin_set/default')
                                        .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      allow(query_service).to receive(:find_by).with(id: Hyrax::AdminSetCreateService::DEFAULT_ID)
                                        .and_raise(Valkyrie::Persistence::ObjectNotFoundError)

      result = Hyrax::AdminSetCreateService.send(:find_unsaved_default_admin_set)

      expect(result).to be_nil
      expect(query_service).to have_received(:find_by).with(id: 'admin_set/default')
      expect(query_service).to have_received(:find_by).with(id: Hyrax::AdminSetCreateService::DEFAULT_ID)
    end
  end
end
