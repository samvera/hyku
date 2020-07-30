# frozen_string_literal: true

RSpec.describe "labels/edit", type: :view do
  let(:site) { Site.create!(application_name: "MyString", institution_name: "My Inst Name") }

  before do
    assign(:site, site)
  end

  it "renders the edit site form" do
    render

    assert_select "form[action=?][method=?]", site_labels_path, "post" do
      assert_select "input#site_application_name[name=?]", "site[application_name]"
      assert_select "input#site_institution_name[name=?]", "site[institution_name]"
      assert_select "input#site_institution_name_full[name=?]", "site[institution_name_full]"
    end
  end
end
