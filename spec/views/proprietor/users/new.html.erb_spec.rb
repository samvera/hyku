# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "proprietor/users/new", type: :view do
  before do
    assign(:user, User.new(
                    email: "email@example.com",
                    password: "Testing123",
                    facebook_handle: "MyString",
                    twitter_handle: "MyString",
                    googleplus_handle: "MyString",
                    display_name: "MyString",
                    address: "MyString",
                    department: "MyString",
                    title: "MyString",
                    office: "MyString",
                    chat_id: "MyString",
                    website: "MyString",
                    affiliation: "MyString",
                    telephone: "MyString",
                    avatar: "",
                    group_list: "MyText",
                    linkedin_handle: "MyString",
                    orcid: "0000-0000-0000-0000",
                    arkivo_token: "MyString",
                    arkivo_subscription: "MyString",
                    zotero_token: "",
                    zotero_userid: "MyString",
                    preferred_locale: "MyString"
                  ))
  end

  it "renders new proprietor_user form" do
    render
    assert_select "form[action=?][method=?]", proprietor_users_path, "post" do
      expect_social_fields
      expect_contact_fields
      expect_additional_fields
    end
  end
end
