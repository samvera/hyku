require 'rails_helper'

RSpec.feature 'Creating a new Work' do
  let(:user) { create(:user) }

  before do
    login_as user, scope: :user
  end

  it 'creates the work' do
    visit '/'
    click_link "Share Your Work"
    expect(page).to have_content "Add New Work"
  end
end
