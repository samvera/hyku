# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Hyku
  module Forms
    module Admin
      # An object to model and persist the form data for the appearance
      # customization menu
      # rubocop:disable Metrics/ClassLength
      class Appearance < Hyrax::Forms::Admin::Appearance
        delegate :banner_image, :banner_image?, :banner_image=, to: :site
        delegate :logo_image, :logo_image?, :logo_image=, to: :site
        delegate :favicon, :favicon?, to: :site
        delegate :directory_image, :directory_image?, to: :site
        delegate :default_collection_image, :default_collection_image?, to: :site
        delegate :default_work_image, :default_work_image?, to: :site

        ##
        # @!group Class Attributes
        #
        # @!attribute default_fonts
        #   @return [Hash<String, String>] there should be at least the key "body_font" and
        #           "headline_font"
        class_attribute :default_fonts, default: {
          'body_font' => 'Helvetica Neue, Helvetica, Arial, sans-serif;',
          'headline_font' => 'Helvetica Neue, Helvetica, Arial, sans-serif;'
        }

        ##
        # @!attribute default_colors
        #   @return [Hash<String, String>]
        class_attribute :default_colors, default: {
          'active_tabs_background_color' => '#f5f5f5',
          'collection_banner_text_color' => '#000000',
          'default_button_background_color' => '#ffffff',
          'default_button_border_color' => '#cccccc',
          'default_button_text_color' => '#333333',
          'facet_panel_background_color' => '#f5f5f5',
          'facet_panel_text_color' => '#333333',
          'footer_link_color' => '#ffebcd',
          'footer_link_hover_color' => '#ffffff',
          'header_and_footer_background_color' => '#3c3c3c',
          'header_and_footer_text_color' => '#dcdcdc',
          'link_color' => '#2e74b2',
          'link_hover_color' => '#215480',
          'navbar_background_color' => '#000000',
          'navbar_link_background_color' => '#375f8c',
          'navbar_link_background_hover_color' => '#ffffff',
          'navbar_link_text_color' => '#eeeeee',
          'navbar_link_text_hover_color' => '#eeeeee',
          'primary_button_background_color' => '#286090',
          'primary_button_border_color' => '#245682',
          'primary_button_hover_color' => '#286090',
          'primary_button_text_color' => '#ffffff'
        }

        # rubocop:disable Metrics/BlockLength
        class << self
          # Override this method if your form takes more than just the customization_params
          def permitted_params
            customization_params + image_params
          end

          def image_params
            %i[favicon banner_image logo_image directory_image default_collection_image default_work_image]
          end

          # A list of parameters that are related to customizations
          # rubocop:disable Metrics/MethodLength
          def customization_params
            %i[
              active_tabs_background_color
              banner_image_text
              body_font
              collection_banner_text_color
              custom_css_block
              default_button_background_color
              default_button_border_color
              default_button_text_color
              default_collection_image_text
              default_work_image_text
              directory_image_alt_text
              directory_image_text
              facet_panel_background_color
              facet_panel_text_color
              footer_link_color
              footer_link_hover_color
              header_and_footer_background_color
              header_and_footer_text_color
              headline_font
              link_color
              link_hover_color
              logo_image_text
              navbar_background_color
              navbar_link_background_color
              navbar_link_background_hover_color
              navbar_link_text_color
              navbar_link_text_hover_color
              primary_button_background_color
              primary_button_border_color
              primary_button_hover_color
              primary_button_text_color
            ]
          end
          # rubocop:enable Metrics/MethodLength

          # @return [Array<Symbol>] a list of fields that are related to the banner
          def banner_fields
            %i[
              banner_image banner_label
            ]
          end

          def favicon_fields
            %i[
              favicon
            ]
          end

          # @return [Array<Symbol>] a list of fields that are related to the logo
          def logo_fields
            %i[
              logo_image logo_label
            ]
          end

          # @return [Array<Symbol>] a list of fields that are related to the directory
          def directory_fields
            %i[
              directory_image directory_image_label directory_image_alt_text
            ]
          end

          # @return [Array<Symbol>] a list of fields that are related to default works & collections
          def default_image_fields
            %i[
              default_collection_image
              default_work_image
              default_collection_label
              default_work_label
            ]
          end
        end
        # rubocop:enable Metrics/BlockLength

        # Required to back a form
        def to_key
          []
        end

        # Required to back a form (for route determination)
        def persisted?
          true
        end

        def site
          @site ||= Site.instance
        end

        def custom_theme_colors
          @home_theme_information ||= YAML.load_file(Hyku::Application.path_for('config/home_themes.yml'))
          current_theme = site&.home_theme || 'default_home'
          @home_theme_information.dig(current_theme, 'theme_custom_colors') || {}
        end

        # The color for the collection banner text
        def collection_banner_text_color
          block_for('collection_banner_text_color')
        end

        # The alt text for the logo image
        def logo_image_text
          block_for('logo_image_text')
        end

        # The alt text for the banner image
        def banner_image_text
          block_for('banner_image_text')
        end

        # The alt text for the directory image
        def directory_image_text
          block_for('directory_image_text')
        end

        # The alt text for the directory image
        def directory_image_alt_text
          block_for('directory_image_alt_text')
        end

        # The alt text for the default_collection image
        def default_collection_image_text
          block_for('default_collection_image_text')
        end

        # The alt text for the default_work image
        def default_work_image_text
          block_for('default_work_image_text')
        end

        # The font for the body copy
        def body_font
          block_for('body_font')
        end

        # The font for the headline copy
        def headline_font
          block_for('headline_font')
        end

        # The color for the background of the header and footer bars
        def header_and_footer_background_color
          block_for('header_and_footer_background_color')
        end

        # The color for the text in the header bar
        def header_and_footer_text_color
          block_for('header_and_footer_text_color')
        end

        # The color for the background of the search navbar
        def navbar_background_color
          block_for('navbar_background_color')
        end

        def navbar_background_color_alpha
          convert_to_rgba(navbar_background_color, 0.4)
        end

        def navbar_background_color_active
          darken_color(navbar_background_color, 0.35)
        end

        def navbar_link_background_color
          block_for('navbar_link_background_color')
        end

        def navbar_link_background_color_active
          darken_color(navbar_link_background_color, 0.35)
        end

        def navbar_link_background_hover_color
          block_for('navbar_link_background_hover_color')
        end

        def navbar_link_background_hover_color_alpha
          convert_to_rgba(navbar_link_background_hover_color, 0.15)
        end

        def navbar_link_text_color
          block_for('navbar_link_text_color')
        end

        def navbar_link_text_hover_color
          block_for('navbar_link_text_hover_color')
        end

        # The color links
        def link_color
          block_for('link_color')
        end

        # The color for links when hover or focus state
        def link_hover_color
          block_for('link_hover_color', darken_color(link_color, 0.15))
        end

        # The color for links in the footer
        def footer_link_color
          block_for('footer_link_color')
        end

        # The color for links when hover in the footer
        def footer_link_hover_color
          block_for('footer_link_hover_color')
        end

        # PRIMARY BUTTON COLORS
        # The background color for "primary" buttons
        def primary_button_background_color
          block_for('primary_button_background_color')
        end

        # The border color for "primary" buttons
        def primary_button_border_color
          block_for('primary_button_border_color')
        end

        def primary_button_hover_color
          block_for('primary_button_hover_color')
        end

        # The text color for "primary" buttons
        def primary_button_text_color
          block_for('primary_button_text_color')
        end

        # The mouse over color for the border of "primary" buttons
        def primary_button_hover_border_color
          darken_color(primary_button_border_color, 0.12)
        end

        # The color for the border of active "primary" buttons
        def primary_button_active_border_color
          darken_color(primary_button_border_color, 0.12)
        end

        # The color for the border of focused "primary" buttons
        def primary_button_focus_border_color
          darken_color(primary_button_border_color, 0.25)
        end

        # The mouse over color for "primary" buttons
        def primary_button_hover_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        # The color for the background of active "primary" buttons
        def primary_button_active_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        # The color for the background of focused "primary" buttons
        def primary_button_focus_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        # The custom css module
        def custom_css_block
          # we want to be able to read the css
          # rubocop:disable Rails/OutputSafety
          block_for('custom_css_block', '/* custom stylesheet */').html_safe
          # rubocop:enable Rails/OutputSafety
        end

        # DEFAULT BUTTON COLORS

        # The background color for "default" buttons
        def default_button_background_color
          block_for('default_button_background_color')
        end

        # The border color for "default" buttons
        def default_button_border_color
          block_for('default_button_border_color')
        end

        # The text color for "default" buttons
        def default_button_text_color
          block_for('default_button_text_color')
        end

        # The mouse over color for "default" buttons
        def default_button_hover_background_color
          darken_color(default_button_background_color, 0.1)
        end

        # The mouse over color for the border of "default" buttons
        def default_button_hover_border_color
          darken_color(default_button_border_color, 0.12)
        end

        # The color for the background of active "default" buttons
        def default_button_active_background_color
          darken_color(default_button_background_color, 0.1)
        end

        # The color for the border of active "default" buttons
        def default_button_active_border_color
          darken_color(default_button_border_color, 0.12)
        end

        # The color for the background of focused "default" buttons
        def default_button_focus_background_color
          darken_color(default_button_background_color, 0.1)
        end

        # The color for the border of focused "default" buttons
        def default_button_focus_border_color
          darken_color(default_button_border_color, 0.25)
        end

        # The color for the background of the home page nav-pills tab with active class
        def active_tabs_background_color
          block_for('active_tabs_background_color')
        end

        # The color for the border of navbar-inverse
        def header_background_border_color
          darken_color(header_and_footer_background_color, 0.25)
        end

        # The color for the facet panel header background color
        def facet_panel_background_color
          block_for('facet_panel_background_color')
        end

        # The color for the facet header text
        def facet_panel_text_color
          block_for('facet_panel_text_color')
        end

        # The color for the facet borders
        def facet_panel_border_color
          darken_color(facet_panel_background_color, 0.12)
        end

        # @return [Hash] attributes that are related to the banner
        def banner_attributes
          attributes.slice(*self.class.banner_fields)
        end

        # @return [Hash] attributes that are related to the banner
        def logo_attributes
          attributes.slice(*self.class.logo_fields)
        end

        def favicon_attributes
          attributes.slice(*self.class.favicon_fields)
        end

        def directory_attributes
          attributes.slice(*self.class.directory_fields)
        end

        def default_image_attributes
          attributes.slice(*self.class.default_image_fields)
        end

        # Persist the form values
        def update!
          self.class.customization_params.each do |field|
            update_block(field, attributes[field]) if attributes[field]
          end

          site.update!(banner_attributes.merge(logo_attributes)
                                        .merge(favicon_attributes)
                                        .merge(directory_attributes)
                                        .merge(default_image_attributes))
        end

        def font_import_body_url
          body = body_font.split('|').first.to_s.tr(" ", "+")
          # we need to be able to read the url to import fonts
          "fonts.googleapis.com/css?family=#{body}"
        end

        def font_import_headline_url
          headline = headline_font.split('|').first.to_s.tr(" ", "+")
          "fonts.googleapis.com/css?family=#{headline}"
        end

        def font_body_family
          format_font_names(body_font)
        end

        def font_headline_family
          format_font_names(headline_font)
        end

        def default_values
          @default_values ||= default_fonts.merge(default_colors)
        end

        private

        def darken_color(hex_color, adjustment = 0.2)
          amount = 1.0 - adjustment
          hex_color = hex_color.delete('#')
          rgb = hex_color.scan(/../).map { |color| (color.to_i(16) * amount).round }
          rgb[0] = (rgb[0].to_i * amount).round
          rgb[1] = (rgb[1].to_i * amount).round
          rgb[2] = (rgb[2].to_i * amount).round
          format("#%02x%02x%02x", *rgb)
        end

        def convert_to_rgba(hex_color, alpha = 0.5)
          hex_color = hex_color.delete('#')
          rgb = hex_color.scan(/../).map(&:hex)
          "rgba(#{rgb[0]}, #{rgb[1]}, #{rgb[2]}, #{alpha})"
        end

        def block_for(name, dynamic_default = nil)
          ContentBlock.block_for(name:, fallback_value: default_values[name] || dynamic_default)
        end

        # Persist a key/value tuple as a ContentBlock
        # @param [Symbol] name the identifier for the ContentBlock
        # @param [String] value the value to set
        def update_block(name, value)
          ContentBlock.update_block(name:, value:)
        end

        def format_font_names(font_style)
          # the fonts come with `Font Name:font-weight` - this removes the weight
          parts = font_style.split(':')
          # Google fonts use `+` in place of spaces. This fixes it for CSS.
          # rubocop:disable Rails/OutputSafety
          parts[0].tr('+', ' ').html_safe
          # rubocop:enable Rails/OutputSafety
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
# rubocop:enable Metrics/ModuleLength
