# frozen_string_literal: true

RSpec.describe Hyrax::Actors::FeaturedCollectionActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:user) { create(:user).tap { |u| u.add_role(:admin, Site.instance) } }
  let(:account) { create(:account) }
  let(:collection) { create(:collection, user: user) }
  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(collection, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:attributes) { {} }

  before do
    Site.update(account: account)
  end

  # rubocop:disable Metrics/LineLength, Lint/AmbiguousBlockAssociation, RSpec/LetSetup
  describe "#destroy" do
    let!(:feature) { FeaturedCollection.create(collection_id: collection.id) }

    it 'removes all the features' do
      expect { middleware.destroy(env) }.to change { FeaturedCollection.where(collection_id: collection.id).count }.from(1).to(0)
    end
  end

  describe "#update" do
    context "of a public collection" do
      let(:collection) { create(:collection) }

      it "does not modify the features" do
        expect { middleware.update(env) }.not_to change { FeaturedCollection.where(collection_id: collection.id).count }
      end
    end

    context "of a private collection" do
      let!(:feature) { FeaturedCollection.create(collection_id: collection.id) }

      it "removes the features" do
        expect { middleware.update(env) }.to change { FeaturedCollection.where(collection_id: collection.id).count }.from(1).to(0)
      end
    end
  end
  # rubocop:enable Metrics/LineLength, Lint/AmbiguousBlockAssociation, RSpec/LetSetup
end
