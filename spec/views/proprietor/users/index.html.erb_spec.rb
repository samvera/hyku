# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "proprietor/users/index", type: :view do
  before do
    assign(:users, [
             User.create!(
               email: "email@example.com",
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
             ),
             User.create!(
               email: "email1@example.com",
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
             )
           ])
  end

  it "renders a list of proprietor/users" do
    render
    assert_select "tr>td", text: "email@example.com".to_s, count: 1
    assert_select "tr>td", text: "email1@example.com".to_s, count: 1
  end
end
