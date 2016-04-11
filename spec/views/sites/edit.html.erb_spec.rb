require 'rails_helper'

RSpec.describe "sites/edit", type: :view do
  let!(:site) do
    assign(:site, Site.create!(application_name: "MyString", institution_name: "My Inst Name"))
  end

  it "renders the edit site form" do
    render

    assert_select "form[action=?][method=?]", site_path, "post" do
      assert_select "input#site_application_name[name=?]", "site[application_name]"
      assert_select "input#site_institution_name[name=?]", "site[institution_name]"
    end
  end
end
