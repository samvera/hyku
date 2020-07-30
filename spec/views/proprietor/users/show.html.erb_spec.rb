# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "proprietor/users/show", type: :view do
  before do
    @user = assign(:user, User.create!(
                            email: "Email@example.com",
                            password: "Testing123",
                            facebook_handle: "Facebook Handle",
                            twitter_handle: "Twitter Handle",
                            googleplus_handle: "Googleplus Handle",
                            display_name: "Display Name",
                            address: "Address",
                            department: "Department",
                            title: "Title",
                            office: "Office",
                            chat_id: "Chat",
                            website: "Website",
                            affiliation: "Affiliation",
                            telephone: "Telephone",
                            avatar: "",
                            group_list: "MyText",
                            linkedin_handle: "Linkedin Handle",
                            orcid: "0000-0000-0000-0000",
                            arkivo_token: "Arkivo Token",
                            arkivo_subscription: "Arkivo Subscription",
                            zotero_token: "",
                            zotero_userid: "Zotero Userid",
                            preferred_locale: "Preferred Locale"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/email@example.com/)
  end
end
