# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::Admin::UsersPresenter do
  subject(:instance) { described_class.new }
  describe '#search' do
    subject { instance.send(:search) }

    it { is_expected.to be_a(Array) }

    context '#super_method' do
      subject { instance.method(:search).super_method }

      it 'is in Hyrax' do
        expect(subject.source_location[0]).to eq(Hyrax::Engine.root.join("app", "presenters", "hyrax", "admin", "users_presenter.rb").to_s)
      end
    end
  end
end
