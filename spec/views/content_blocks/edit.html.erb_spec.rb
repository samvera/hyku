require 'rails_helper'

RSpec.describe "content_blocks/edit", type: :view do
  let(:site) { Site.create!(application_name: "MyString", institution_name: "My Inst Name") }

  before do
    assign(:site, site)
  end

  it "renders the edit site form" do
    render

    assert_select "form[action=?][method=?]", site_content_blocks_path, "post" do
      assert_select "textarea#site_announcement_text[name=?]", "site[announcement_text]"
      assert_select "textarea#site_marketing_text[name=?]", "site[marketing_text]"
      assert_select "textarea#site_featured_researcher[name=?]", "site[featured_researcher]"
      assert_select "textarea#site_about_page[name=?]", "site[about_page]"
    end
  end
end
