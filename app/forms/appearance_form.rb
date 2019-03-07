# The for for the color picker and background setter
class AppearanceForm < Hyrax::Forms::Admin::Appearance
  delegate :banner_image, :banner_image?, to: :site
  delegate :logo_image, :logo_image?, to: :site
  delegate :default_collection_image, :default_collection_image?, to: :site
  delegate :default_work_image, :default_work_image?, to: :site

  # @return [Array<Symbol>] a list of fields that are related to the banner
  def self.banner_fields
    [:banner_image]
  end

  def self.default_image_fields
    [:default_collection_image, :default_work_image]
  end

  # @return [Array<Symbol>] a list of fields that are related to the banner
  def self.logo_fields
    [:logo_image]
  end

  # Whitelisted parameters
  def self.permitted_params
    super + banner_fields + logo_fields + default_image_fields
  end

  def site
    @site ||= Site.instance
  end

  def update!
    super && site.update(banner_attributes.merge(logo_attributes).merge(default_image_attributes))
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

    def default_image_attributes
      attributes.slice(*self.class.default_image_fields)
    end
    
end
