class Site < ApplicationRecord
  resourcify

  validates :application_name, presence: true, allow_nil: true

  # Allow for uploading of site's banner image
  mount_uploader :banner_image, Hyrax::UploadedFileUploader
  # Allow for uploading of site's logo image
  mount_uploader :logo_image, Hyrax::AvatarUploader
  # Allow for uploading of site's directory image
  mount_uploader :directory_image, Hyrax::AvatarUploader
  # Allow for uploading of site's default collection image
  mount_uploader :default_collection_image, Hyrax::AvatarUploader
  # Allow for uploading of site's default work image
  mount_uploader :default_work_image, Hyrax::AvatarUploader

  belongs_to :account
  accepts_nested_attributes_for :account, update_only: true

  class << self
    delegate :account, :application_name, :institution_name,
             :institution_name_full, :reload, :update,
             to: :instance

    def instance
      return NilSite.instance if Account.global_tenant?
      first_or_create do |site|
        site.available_works = Hyrax.config.registered_curation_concern_types
      end
    end
  end

  # Get all administrator emails associated with this site
  def admin_emails
    User.with_role(:admin, self).pluck(:email)
  end

  # Update administrator emails associated with this site
  # @param [Array<String>] Array of user emails
  def admin_emails=(emails)
    existing_admin_emails = admin_emails
    new_admin_emails = emails - existing_admin_emails
    removed_admin_emails = existing_admin_emails - emails
    add_admins_by_email(new_admin_emails) if new_admin_emails
    remove_admins_by_email(removed_admin_emails) if removed_admin_emails
  end

  private

    # Add/invite admins via email address
    # @param [Array<String>] Array of user emails
    def add_admins_by_email(emails)
      # For users that already have accounts, add to role immediately
      existing_emails = User.where(email: emails).map do |u|
        u.add_role :admin, self
        u.email
      end
      # For new users, send invitation and add to role
      (emails - existing_emails).each do |email|
        u = User.invite!(email: email)
        u.add_role :admin, self
      end
    end

    # Remove specific administrators
    # @param [Array<String>] Array of user emails
    def remove_admins_by_email(emails)
      User.where(email: emails).find_each do |u|
        u.remove_role :admin, self
      end
    end
end
