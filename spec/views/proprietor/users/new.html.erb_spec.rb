require 'rails_helper'

RSpec.describe "proprietor/users/new", type: :view do
  before(:each) do
    assign(:proprietor_user, User.new(
      :email => "MyString",
      :facebook_handle => "MyString",
      :twitter_handle => "MyString",
      :googleplus_handle => "MyString",
      :display_name => "MyString",
      :address => "MyString",
      :department => "MyString",
      :title => "MyString",
      :office => "MyString",
      :chat_id => "MyString",
      :website => "MyString",
      :affiliation => "MyString",
      :telephone => "MyString",
      :avatar => "",
      :group_list => "MyText",
      :linkedin_handle => "MyString",
      :orcid => "MyString",
      :arkivo_token => "MyString",
      :arkivo_subscription => "MyString",
      :zotero_token => "",
      :zotero_userid => "MyString",
      :preferred_locale => "MyString"
    ))
  end

  it "renders new proprietor_user form" do
    skip
    render

    assert_select "form[action=?][method=?]", users_path, "post" do

      assert_select "input[name=?]", "proprietor_user[email]"

      assert_select "input[name=?]", "proprietor_user[facebook_handle]"

      assert_select "input[name=?]", "proprietor_user[twitter_handle]"

      assert_select "input[name=?]", "proprietor_user[googleplus_handle]"

      assert_select "input[name=?]", "proprietor_user[display_name]"

      assert_select "input[name=?]", "proprietor_user[address]"

      assert_select "input[name=?]", "proprietor_user[department]"

      assert_select "input[name=?]", "proprietor_user[title]"

      assert_select "input[name=?]", "proprietor_user[office]"

      assert_select "input[name=?]", "proprietor_user[chat_id]"

      assert_select "input[name=?]", "proprietor_user[website]"

      assert_select "input[name=?]", "proprietor_user[affiliation]"

      assert_select "input[name=?]", "proprietor_user[telephone]"

      assert_select "input[name=?]", "proprietor_user[avatar]"

      assert_select "textarea[name=?]", "proprietor_user[group_list]"

      assert_select "input[name=?]", "proprietor_user[linkedin_handle]"

      assert_select "input[name=?]", "proprietor_user[orcid]"

      assert_select "input[name=?]", "proprietor_user[arkivo_token]"

      assert_select "input[name=?]", "proprietor_user[arkivo_subscription]"

      assert_select "input[name=?]", "proprietor_user[zotero_token]"

      assert_select "input[name=?]", "proprietor_user[zotero_userid]"

      assert_select "input[name=?]", "proprietor_user[preferred_locale]"
    end
  end
end
