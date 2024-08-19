# frozen_string_literal: true

# NilSite is used to represent the Site in the global tenant in a multitenant environment
# (i.e. Sites only exist on individual tenants and never globally)
class NilSite
  class << self
    # NilSite must be a singleton like Site
    attr_writer :instance
    def instance
      @instance ||= NilSite.new
    end
  end

  # Return nil for all these attributes
  attr_reader :id, :account, :application_name, :institution_name,
              :institution_name_full, :banner_image, :primary_key,
              :logo_image, :default_collection_image, :default_work_image,
              :directory_image, :favicon, :contact_email

  # rubocop:disable Lint/DuplicateMethods
  def reload
    NilSite.instance
  end

  def update(*)
    false
  end

  def admin_emails
    []
  end

  def admin_emails=(value)
    value
  end

  def favicon
    "favicon.ico"
  end

  def banner_image?
    false
  end

  def logo_image?
    false
  end

  def directory_image?
    false
  end

  def default_collection_image?
    false
  end

  def default_collection_image
    nil
  end

  def default_work_image?
    false
  end

  def default_work_image
    nil
  end
  # rubocop:enable Lint/DuplicateMethods
end
