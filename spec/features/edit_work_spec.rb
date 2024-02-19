# frozen_string_literal: true

# NOTE: If want to run spec in browser, you have to set "js: true"
RSpec.describe 'Editing an existing Work', type: :feature, js: true, clean: true do
  let(:admin_user) { create(:admin) }
  let(:work) { FactoryBot.valkyrie_create(:generic_work_resource) }

  before do
    FactoryBot.create(:admin_group)
    login_as admin_user
  end

  context 'sharing a work' do
    let!(:group) { FactoryBot.create(:group, name: 'dummy') }

    it 'displays the groups humanized name' do
      visit "/concern/generic_works/#{ERB::Util.url_encode(work.id)}/edit#share"

      expect(page).to have_content 'Add Sharing'
      expect(page.has_select?('new_group_name_skel', with_options: [group.humanized_name])).to be true
    end
  end
end
