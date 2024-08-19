# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Oer`
require 'rails_helper'

RSpec.describe Hyrax::Actors::OerActor, skip: 'In Valkyrie, transactions replaced actors' do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:work) { create(:oer_work) }
  let(:related_oer) { create(:oer_work) }
  let(:previous_oer) { create(:oer_work) }
  let(:newer_oer) { create(:oer_work) }
  let(:alternate_oer) { create(:oer_work) }
  let(:related_item_oer) { create(:oer_work) }
  let(:attributes) do
    HashWithIndifferentAccess.new(related_members_attributes: {
                                    '0' => { id: previous_oer.id, _destroy: 'false', relationship: 'previous-version' },
                                    '1' => { id: newer_oer.id, _destroy: 'false', relationship: 'newer_version' },
                                    '2' => { id: alternate_oer.id, _destroy: 'false', relationship: 'alternate-version' },
                                    '3' => { id: related_item_oer.id, _destroy: 'false', relationship: 'related-item' }
                                  })
  end

  describe "#create" do
    it 'adds a related version' do
      expect(subject.create(env)).to be true
      expect(work.previous_version_id).to eq([previous_oer.id])
    end
  end

  describe "#update" do
    it 'updates the previous version items' do
      expect(subject.update(env)).to be true
      expect(work.previous_version_id).to eq([previous_oer.id])
    end

    it 'updates the newer version items' do
      expect(subject.update(env)).to be true
      expect(work.newer_version_id).to eq([newer_oer.id])
    end

    it 'updates the alternate version' do
      expect(subject.update(env)).to be true
      expect(work.alternate_version_id).to eq([alternate_oer.id])
    end

    it 'updates the related item' do
      expect(subject.update(env)).to be true
      expect(work.related_item_id).to eq([related_item_oer.id])
    end

    before { subject.update(env) }

    it 'removes the related version items' do
      attributes =  HashWithIndifferentAccess.new(related_members_attributes: {
                                                    '0' => { id: previous_oer.id, _destroy: 'true', relationship: 'previous-version' },
                                                    '1' => { id: newer_oer.id, _destroy: 'true', relationship: 'newer-version' },
                                                    '2' => { id: alternate_oer.id, _destroy: 'true', relationship: 'alternate-version' },
                                                    '3' => { id: related_item_oer.id, _destroy: 'true', relationship: 'related-item' }
                                                  })

      env = Hyrax::Actors::Environment.new(work, ability, attributes)

      expect(subject.update(env)).to be true
      expect(work.previous_version_id).to eq([])
      expect(work.newer_version_id).to eq([])
      expect(work.alternate_version_id).to eq([])
      expect(work.related_item_id).to eq([])
    end

    before { subject.update(env) }

    it 'adds and removes relationships on same submit' do
      attributes = HashWithIndifferentAccess.new(related_members_attributes: {
                                                   '0' => { id: previous_oer.id, _destroy: 'true', relationship: 'previous-version' },
                                                   '1' => { id: newer_oer.id, _destroy: 'false', relationship: 'newer-version' },
                                                   '2' => { id: alternate_oer.id, _destroy: 'true', relationship: 'alternate-version' },
                                                   '3' => { id: related_item_oer.id, _destroy: 'false', relationship: 'related-item' }
                                                 })

      env = Hyrax::Actors::Environment.new(work, ability, attributes)

      expect(subject.update(env)).to be true
      expect(work.previous_version_id).to eq([])
      expect(work.newer_version_id).to eq([newer_oer.id])
      expect(work.alternate_version_id).to eq([])
      expect(work.related_item_id).to eq([related_item_oer.id])
    end
  end
end
