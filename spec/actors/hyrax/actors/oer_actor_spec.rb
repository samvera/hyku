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
  let(:attributes) { HashWithIndifferentAccess.new(related_members_attributes: { '0' => { id: related_oer.id } }) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#create" do
    it 'adds a related version' do
      expect(subject.create(env)).to be true
      expect(work.previous_version).to eq([related_oer])
    end
  end

  describe "#update" do
    # before do
    #   subject.create(env)
    # end

    let(:new_related_oer) { create(:oer_work) }
    let(:attributes) { HashWithIndifferentAccess.new(related_members_attributes: { '0' => { id: related_oer.id, _destroy: 'false' }, '1' => { id: new_related_oer.id, _destroy: 'false' } }) }

    it 'updates a related version' do
      expect(subject.update(env)).to be true
      expect(work.previous_version).to eq([related_oer, new_related_oer])
    end
    let(:attributes) { HashWithIndifferentAccess.new(related_members_attributes: { '0' => { id: related_oer.id, _destroy: 'true' }, '1' => { id: new_related_oer.id, _destroy: 'false' } }) }

    it 'removes the related version' do
      expect(subject.update(env)).to be true
      expect(work.previous_version).to eq([new_related_oer])
    end
  end

end
