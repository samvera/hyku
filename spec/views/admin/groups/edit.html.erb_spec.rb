# frozen_string_literal: true

RSpec.describe 'admin/groups/edit', type: :view do
  include Warden::Test::Helpers
  include Devise::Test::ControllerHelpers

  context 'groups index page' do
    let(:group) { FactoryBot.create(:group) }

    before do
      allow(controller).to receive(:params).and_return(
        controller: 'admin/groups',
        action: 'edit',
        id: group.id
      )
      assign(:group, group)
      render
    end

    it 'has the "description" tab in an active state' do
      expect(rendered).to have_selector('.nav-tabs .nav-item .nav-link.active', text: 'Description')
    end

    it 'has tabs for other actions on the group' do
      expect(rendered).to have_selector('.nav-tabs .nav-item a', text: 'Users')
      expect(rendered).to have_selector('.nav-tabs .nav-item a', text: 'Remove')
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
