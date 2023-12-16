# frozen_string_literal: true

require 'importer'

RSpec.describe Importer::Factory::ImageFactory, :clean do
  let(:factory) { described_class.new(attributes) }
  let(:files) { [] }
  let(:work) { Image }

  context 'when a collection already exists' do
    let!(:coll) { create(:collection) }
    let(:attributes) do
      {
        collection: { id: coll.id },
        files:,
        identifier: ['123'],
        title: ['Test image'],
        read_groups: ['public'],
        depositor: 'bob',
        edit_users: ['bob']
      }
    end
    let(:actor) { Hyrax::CurationConcern.actor }

    it 'does not create a new collection' do
      expect(actor).to receive(:create).with(Hyrax::Actors::Environment) do |k|
        expect(k.attributes).to include(member_of_collection_attributes: [id: coll.id])
      end
      expect do
        factory.run
      end.to change(Collection, :count).by(0)
    end
  end

  include_examples("csv_importer")
end
