# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "The homepage", :clean_repo do
  let(:user) { create(:user).tap { |u| u.add_role(:admin, Site.instance) } }
  let(:account) { create(:account) }
  let(:collection1) { create(:collection, user:) }
  let(:collection2) { create(:collection, user:) }

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
