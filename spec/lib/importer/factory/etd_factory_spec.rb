require 'importer'

RSpec.describe Importer::Factory::ETDFactory, :clean do
  let(:factory) { described_class.new(attributes) }
  let(:files) { [] }
  let(:work) { GenericWork }

  # context 'with files' do
  #   let(:factory) { described_class.new(attributes, 'tmp/files', files) }
  #   let(:files) { ['img.png'] }
  #   let(:coll) { create(:collection) }
  #
  #   context "for a new image" do
  #     it 'calls the actor with the files' do
  #       expect(actor).to receive(:create).with(Hyrax::Actors::Environment) do |k|
  #         expect(k.attributes).to include(member_of_collection_ids: [coll.id], files: ['tmp/files/img.png'])
  #       end
  #       factory.run
  #     end
  #   end
  #
  #   context "for an existing image without files" do
  #     let(:work) { create(:generic_work) }
  #     let(:factory) { described_class.new(attributes.merge(id: work.id), 'tmp/files', files) }
  #
  #     it 'creates file sets' do
  #       expect(actor).to receive(:update).with(Hyrax::Actors::Environment) do |k|
  #         expect(k.attributes).to include(member_of_collection_ids: [coll.id], files: ['tmp/files/img.png'])
  #       end
  #       factory.run
  #     end
  #   end
  # end

  context 'when a collection already exists' do
    let!(:coll) { create(:collection) }
    let(:attributes) do
      {
        collection: { id: coll.id },
        files: files,
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
        expect(k.attributes).to include(member_of_collection_ids: [coll.id])
      end
      expect do
        factory.run
      end.to change(Collection, :count).by(0)
    end
  end

  include_examples("csv_importer")
end
