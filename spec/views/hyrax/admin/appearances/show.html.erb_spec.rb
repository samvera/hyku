# frozen_string_literal: true

RSpec.describe "hyrax/admin/appearances/show", type: :view do
  let(:form) { AppearanceForm.new }

  before do
    without_partial_double_verification do
      allow(view).to receive(:admin_appearance_path).and_return('/path')
      assign(:form, form)
      render
    end
  end

  it "renders the edit site form" do
    assert_select "form[action='/path'][method=?]", "post" do
      assert_select "input#admin_appearance_banner_image[name=?]", "admin_appearance[banner_image]"
      assert_select "input#admin_appearance_banner_image[type=?]", "file"
      assert_select "input#admin_appearance_primary_button_background_color[type=?]", "color"
    end
  end
end
