# frozen_string_literal: true

RSpec.describe "hyrax/admin/appearances/show", type: :view do
  let(:form) { Hyrax::Forms::Admin::Appearance.new }

  before do
    without_partial_double_verification do
      allow(view).to receive(:admin_appearance_path).and_return('/path')
      allow(view).to receive(:edit_content_blocks_path).and_return('/path')
      assign(:form, form)
      @home_theme_names = {
        "default_home" =>
          {
            "banner_image" => true,
            "featured_researcher" => true,
            "home_page_text" => false,
            "marketing_text" => true,
            "name" => "Default home"
          },
        "cultural_repository" =>
          {
            "banner_image" => true,
            "featured_researcher" => false,
            "home_page_text" => true,
            "marketing_text" => true,
            "name" => "Cultural Repository"
          }
      }
      @show_theme_names = {
        "default_show" =>
          {
            "name" => "Default Show Page",
            "notes" => "This is the default Hyku show page. It is recommended for use with cultural repositories."
          }
      }
      @search_themes = { 'List view' => 'list_view', 'Gallery view' => 'gallery_view' }
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
      assert_select(
        "input#admin_appearance_default_collection_image[name=?]",
        "admin_appearance[default_collection_image]"
      )
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
