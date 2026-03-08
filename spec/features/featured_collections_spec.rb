# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "The homepage", :clean_repo do
  let(:user) { create(:user).tap { |u| u.add_role(:admin, Site.instance) } }
  let(:account) { create(:account) }
  let(:collection1) { FactoryBot.valkyrie_create(:hyku_collection, title: ["Featured Collection 1"], depositor: user.user_key) }
  let(:collection2) { FactoryBot.valkyrie_create(:hyku_collection, title: ["Featured Collection 2"], depositor: user.user_key) }

  before do
    Site.update(account:)
    create(:featured_collection, collection_id: collection1.id)
  end

  it 'shows featured collections' do
    visit root_path
    expect(page).to have_link collection1.title.first
  end

  context "as an admin" do
    before do
      login_as(user)
    end

    it 'shows featured collections that I can sort' do
      visit root_path
      within '.dd-item' do
        expect(page).to have_link collection1.title.first
      end
    end
  end
end
