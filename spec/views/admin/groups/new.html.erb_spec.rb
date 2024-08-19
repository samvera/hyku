# frozen_string_literal: true

RSpec.describe 'admin/groups/new', type: :view do
  context 'groups index page' do
    let(:group) { FactoryBot.build(:group) }

    before do
      assign(:group, group)
      render
    end

    it 'has the "description" tab in an active state' do
      expect(rendered).to have_selector('.nav-tabs .nav-item .nav-link.active', text: 'Description')
    end

    it 'has disable tabs for actions that require a group to have been created' do
      expect(rendered).to have_selector('.nav-tabs .nav-item a.nav-link.disabled', text: 'Users')
      expect(rendered).to have_selector('.nav-tabs .nav-item a.nav-link.disabled', text: 'Remove')
    end

    it 'has an input for name' do
      expect(rendered).to have_selector('input', id: 'group_humanized_name')
    end

    it 'has a text area for description' do
      expect(rendered).to have_selector('textarea', id: 'group_description')
    end

    it 'has a save button' do
      expect(rendered).to have_selector('input', class: 'action-save')
    end

    it 'has a cancel button' do
      expect(rendered).to have_selector('a', class: 'action-cancel')
    end
  end
end
