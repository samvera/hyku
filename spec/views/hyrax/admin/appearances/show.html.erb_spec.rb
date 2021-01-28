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
      # logo tab
      assert_select "input#admin_appearance_logo_image[name=?]", "admin_appearance[logo_image]"
      # banner image tab
      assert_select "input#admin_appearance_banner_image[name=?]", "admin_appearance[banner_image]"
      assert_select "input#admin_appearance_banner_image[type=?]", "file"
      # directory image
      assert_select "input#admin_appearance_directory_image[name=?]", "admin_appearance[directory_image]"
      # default collection image
      # rubocop:disable Metrics/LineLength
      assert_select "input#admin_appearance_default_collection_image[name=?]", "admin_appearance[default_collection_image]"
      # rubocop:enable Metrics/LineLength
      # default work image
      assert_select "input#admin_appearance_default_work_image[name=?]", "admin_appearance[default_work_image]"
      # colors
      assert_select "input#admin_appearance_primary_button_background_color[type=?]", "color"
      # fonts
      assert_select "input#admin_appearance_body_font[name=?]", "admin_appearance[body_font]"
      # custom css
      assert_select "textarea#admin_appearance_custom_css_block[name=?]", "admin_appearance[custom_css_block]"
    end
    # themes
    assert_select "select#site_home_theme[name=?]", "site[home_theme]"
  end
end
