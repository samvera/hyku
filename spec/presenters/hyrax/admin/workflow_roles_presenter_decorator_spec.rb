# frozen_string_literal: true

RSpec.describe Hyrax::Admin::WorkflowRolesPresenter, type: :decorator do
  subject { described_class.new }

  let(:number_of_groups) { 3 }

  before do
    number_of_groups.times { create(:group) }
  end

  describe '#groups' do
    it 'returns all groups' do
      expect(subject.groups.all? { |group| group.class == Hyrax::Group }).to be true
      expect(subject.groups.count).to eq number_of_groups
    end
  end

  describe '#group_presenter_for' do
    it 'returns a presenter for the given group' do
      expect(subject.group_presenter_for(Hyrax::Group.first).class).to eq Hyrax::Admin::WorkflowRolesPresenter::AgentPresenter
    end
  end
end
