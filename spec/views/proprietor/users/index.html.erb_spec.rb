require 'rails_helper'

RSpec.describe "proprietor/users/index", type: :view do
  before(:each) do
    assign(:users, [
      User.create!(
        :email => "Email",
        :facebook_handle => "Facebook Handle",
        :twitter_handle => "Twitter Handle",
        :googleplus_handle => "Googleplus Handle",
        :display_name => "Display Name",
        :address => "Address",
        :department => "Department",
        :title => "Title",
        :office => "Office",
        :chat_id => "Chat",
        :website => "Website",
        :affiliation => "Affiliation",
        :telephone => "Telephone",
        :avatar => "",
        :group_list => "MyText",
        :linkedin_handle => "Linkedin Handle",
        :orcid => "Orcid",
        :arkivo_token => "Arkivo Token",
        :arkivo_subscription => "Arkivo Subscription",
        :zotero_token => "",
        :zotero_userid => "Zotero Userid",
        :preferred_locale => "Preferred Locale"
      ),
      User.create!(
        :email => "Email",
        :facebook_handle => "Facebook Handle",
        :twitter_handle => "Twitter Handle",
        :googleplus_handle => "Googleplus Handle",
        :display_name => "Display Name",
        :address => "Address",
        :department => "Department",
        :title => "Title",
        :office => "Office",
        :chat_id => "Chat",
        :website => "Website",
        :affiliation => "Affiliation",
        :telephone => "Telephone",
        :avatar => "",
        :group_list => "MyText",
        :linkedin_handle => "Linkedin Handle",
        :orcid => "Orcid",
        :arkivo_token => "Arkivo Token",
        :arkivo_subscription => "Arkivo Subscription",
        :zotero_token => "",
        :zotero_userid => "Zotero Userid",
        :preferred_locale => "Preferred Locale"
      )
    ])
  end

  it "renders a list of proprietor/users" do
    render
    assert_select "tr>td", :text => "Email".to_s, :count => 2
    assert_select "tr>td", :text => "Facebook Handle".to_s, :count => 2
    assert_select "tr>td", :text => "Twitter Handle".to_s, :count => 2
    assert_select "tr>td", :text => "Googleplus Handle".to_s, :count => 2
    assert_select "tr>td", :text => "Display Name".to_s, :count => 2
    assert_select "tr>td", :text => "Address".to_s, :count => 2
    assert_select "tr>td", :text => "Department".to_s, :count => 2
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "Office".to_s, :count => 2
    assert_select "tr>td", :text => "Chat".to_s, :count => 2
    assert_select "tr>td", :text => "Website".to_s, :count => 2
    assert_select "tr>td", :text => "Affiliation".to_s, :count => 2
    assert_select "tr>td", :text => "Telephone".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "Linkedin Handle".to_s, :count => 2
    assert_select "tr>td", :text => "Orcid".to_s, :count => 2
    assert_select "tr>td", :text => "Arkivo Token".to_s, :count => 2
    assert_select "tr>td", :text => "Arkivo Subscription".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "Zotero Userid".to_s, :count => 2
    assert_select "tr>td", :text => "Preferred Locale".to_s, :count => 2
  end
end
