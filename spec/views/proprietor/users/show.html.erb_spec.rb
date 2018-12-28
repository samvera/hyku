require 'rails_helper'

RSpec.describe "proprietor/users/show", type: :view do
  before(:each) do
    @proprietor_user = assign(:proprietor_user, User.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/Facebook Handle/)
    expect(rendered).to match(/Twitter Handle/)
    expect(rendered).to match(/Googleplus Handle/)
    expect(rendered).to match(/Display Name/)
    expect(rendered).to match(/Address/)
    expect(rendered).to match(/Department/)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Office/)
    expect(rendered).to match(/Chat/)
    expect(rendered).to match(/Website/)
    expect(rendered).to match(/Affiliation/)
    expect(rendered).to match(/Telephone/)
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Linkedin Handle/)
    expect(rendered).to match(/Orcid/)
    expect(rendered).to match(/Arkivo Token/)
    expect(rendered).to match(/Arkivo Subscription/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Zotero Userid/)
    expect(rendered).to match(/Preferred Locale/)
  end
end
