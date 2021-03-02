# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin can select feature flags', type: :feature, js: true, clean: true do
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com', display_name: 'Adam Admin') }
  let(:account) { FactoryBot.create(:account) }
  let!(:work) do
    create(:generic_work,
           title: ['Pandas'],
           keyword: ['red panda', 'giant panda'],
           user: admin)
  end
  let!(:collection) do
    create(:public_collection_lw,
           title: ['Pandas'],
           description: ['Giant Pandas and Red Pandas'],
           user: admin,
           members: [work])
  end
  let!(:feature) { FeaturedWork.create(work_id: work.id) }

  context "as a repository admin" do
    it "has a setting for featured works" do
      login_as admin
      visit 'admin/features'
      expect(page).to have_content 'Show featured works'
      find("tr[data-feature='show-featured-works']").find_button('off').click
      visit '/'
      expect(page).to have_content 'Recently Uploaded'
      expect(page).to have_content 'Pandas'
      expect(page).not_to have_content 'Featured Works'
      visit 'admin/features'
      find("tr[data-feature='show-featured-works']").find_button('on').click
      visit '/'
      expect(page).to have_content 'Featured Works'
      expect(page).to have_content 'Pandas'
    end
  end
end
