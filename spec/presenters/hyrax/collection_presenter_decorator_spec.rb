# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::CollectionPresenter, type: :decorator do
  describe '.terms' do
    it 'does not include size' do
      expect(described_class.terms.size).to be_positive
      expect(described_class.terms).not_to include(:size)
    end
  end

  describe '#collection_type_badge' do
    subject { presenter.collection_type_badge }

    # We're decorating an alternate base class so that we don't need the full pre-amble for testing
    # our decoration.  In other words, let's trust Hyrax::CollectionPresenter's specs for the
    # "super" method call.
    let(:base_class) do
      Class.new do
        def collection_type_badge
          "<span>"
        end
        prepend Hyrax::CollectionPresenterDecorator
      end
    end
    let(:presenter) { base_class.new }

    before { allow(Site).to receive(:account).and_return(account) }

    context 'when the Site.account is nil' do
      let(:account) { nil }

      it { is_expected.to eq("") }
    end

    context 'when the Site.account is search_only' do
      let(:account) { FactoryBot.build(:account, search_only: true) }

      it { is_expected.to eq("") }
    end

    context 'when the Site.account is NOT search_only' do
      let(:account) { FactoryBot.build(:account, search_only: false) }

      it { is_expected.to start_with("<span") }
    end

    context 'super_method' do
      subject { Hyrax::CollectionPresenter.instance_method(:collection_type_badge).super_method }

      let(:account) { nil }

      it 'is Hyrax::CollectionPresenter#collection_type_badge' do
        expect(subject.source_location.first).to end_with("app/presenters/hyrax/collection_presenter.rb")
      end
    end
  end
end
