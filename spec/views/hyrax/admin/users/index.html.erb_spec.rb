# frozen_string_literal: true

RSpec.describe 'hyrax/admin/users/index.html.erb', type: :view do
  let(:presenter) { Hyrax::Admin::UsersPresenter.new }
  let(:users) { [] }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    # Create four normal user accounts
    (1..4).each do |i|
      users << FactoryBot.create(
        :user,
        display_name: "user#{i}",
        email: "email#{i}@example.com",
        last_sign_in_at: Time.zone.now - 15.minutes,
        created_at: Time.zone.now - 3.days
      )
    end
    allow(presenter).to receive(:users).and_return(users)
    assign(:presenter, presenter)
    render
  end

  it "draws user invite form" do
    expect(page).to have_selector("div.users-invite")
    expect(page).to have_content("Add or Invite user via email")
    expect(page).to have_selector("div.users-invite input.email")
    expect(page).to have_selector("//input[@value='Invite user']")
  end

  it "draws user list with all users" do
    expect(page).to have_selector("div.users-listing")
    expect(page).to have_content("Username")
    expect(page).to have_content("Roles")
    expect(page).to have_content("Last access")
    expect(page).to have_content("Status")
    expect(page).to have_content("Action")

    # All users should be listed & have status of active
    (1..4).each do |i|
      expect(page).to have_content("email#{i}@example.com")
    end
    expect(page).to have_selector("div.users-listing td", text: 'Active', count: 4)

    # Delete button next to each user
    expect(page).to have_selector('a', class: 'action-delete', count: 4)
  end

  context "with admin users" do
    before do
      # Create two admin acccounts
      (5..6).each do |i|
        users << FactoryBot.create(:admin,
                                   display_name: "admin-user#{i}",
                                   email: "admin#{i}@example.com",
                                   last_sign_in_at: Time.zone.now - 15.minutes,
                                   created_at: Time.zone.now - 3.days)
      end
      render
    end

    it "lists users as having admin role" do
      (5..6).each do |i|
        expect(page).to have_content("admin#{i}@example.com")
      end
      expect(page).to have_selector("div.users-listing li", text: 'admin', count: 2)
    end
  end

  context "with a user who hasn't accepted an invitation" do
    before do
      # Create one invited (pending) user
      (7..7).each do |i|
        users << FactoryBot.create(:invited_user,
                                   display_name: "invitee#{i}",
                                   email: "invitee#{i}@example.com",
                                   last_sign_in_at: Time.zone.now - 15.minutes,
                                   created_at: Time.zone.now - 3.days)
      end
      render
    end

    it "lists one user as pending status, and others as active" do
      (7..7).each do |i|
        expect(page).to have_content("invitee#{i}@example.com")
      end
      expect(page).to have_selector("div.users-listing td", text: 'Pending', count: 1)
    end
  end
end
