# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'

RSpec.describe Hyrax::Actors::OerActor do
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) { create(:oer_work) }
  let(:related_oer) { create(:oer_work) }
  let(:new_related_oer) { create(:oer_work) }
  let(:attributes) { HashWithIndifferentAccess.new(related_members_attributes: { '0' => { id: related_oer.id, _destroy: 'false', relationship: 'previous-version' } }) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#create" do
    it 'adds a related version' do
      expect(subject.create(env)).to be true
      expect(work.previous_version_id).to eq([related_oer.id])
    end
  end

  describe "#update" do
    let(:new_related_oer) { create(:oer_work) }
    let(:attributes) { HashWithIndifferentAccess.new(related_members_attributes: { '0' => { id: related_oer.id, _destroy: 'false', relationship: 'previous-version' }, '1' => { id: new_related_oer.id, _destroy: 'false', relationship: 'newer-version' }, '2' => { id: new_related_oer.id, _destroy: 'false', relationship: 'alternate-version' } }) }

    before { subject.update(env) }

    it 'updates a related version' do
      expect(subject.update(env)).to be true
      expect(work.previous_version_id).to include(related_oer.id)
      expect(work.newer_version_id).to include(new_related_oer.id)
      expect(work.alternate_version_id).to include(new_related_oer.id)
    end

    it 'removes the related version' do
      attributes =  HashWithIndifferentAccess.new(related_members_attributes: { '0' => { id: related_oer.id, _destroy: 'true',relationship: 'previous-version' }, '1' => { id: new_related_oer.id, _destroy: 'false', relationship: 'newer-version' }, '2' => { id: new_related_oer.id, _destroy: 'false', relationship: 'alternate-version' } })
      env =  Hyrax::Actors::Environment.new(work, ability, attributes)
      expect(subject.update(env)).to be true
      expect(work.previous_version_id).to eq([])
      expect(work.newer_version_id).to eq([new_related_oer.id])
      expect(work.alternate_version_id).to eq([new_related_oer.id])
    end
  end

end
