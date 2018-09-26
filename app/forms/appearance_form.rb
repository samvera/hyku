# The for for the color picker and background setter
class AppearanceForm < Hyrax::Forms::Admin::Appearance
  delegate :banner_image, :banner_image?, to: :site
  delegate :logo_image, :logo_image?, to: :site

  # Whitelisted parameters
  def self.permitted_params
    super + banner_fields + logo_fields
  end

  def update!
    super && site.update(banner_attributes.merge(logo_attributes))
  end

  # @return [Array<Symbol>] a list of fields that are related to the banner
  def self.banner_fields
    [:banner_image]
  end

  # @return [Array<Symbol>] a list of fields that are related to the banner
  def self.logo_fields
    [:logo_image]
  end

  def site
    @site ||= Site.instance
  end

  private

    # @return [Hash] attributes that are related to the banner
    def banner_attributes
      attributes.slice(*self.class.banner_fields)
    end

    # @return [Hash] attributes that are related to the banner
    def logo_attributes
      attributes.slice(*self.class.logo_fields)
    end
end
