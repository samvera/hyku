# frozen_string_literal: true

RSpec.describe Hyrax::Admin::DashboardPresenter, type: :decorator do
  let(:presenter) { described_class.new }
  let(:start_date) { Time.zone.today - 1.day }
  let(:end_date) { Time.zone.today + 1.day }
  let(:number_of_users) { 3 }

  describe "#user_count" do
    subject { presenter.user_count(start_date, end_date) }

    it 'is being decorated' do
      expect(presenter.method(:user_count).source_location.first).to end_with('dashboard_presenter_decorator.rb')
    end

    it 'returns the number of users' do
      number_of_users.times { create(:user) }
      expect(subject).to eq number_of_users
    end
  end
end
