# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra

Hydra.configure do |config|
  # This specifies the solr field names of permissions-related fields.
  # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
  # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
  #
  # config.permissions.discover.group       = "discover_access_group_ssim"
  # config.permissions.discover.individual  = "discover_access_person_ssim"
  # config.permissions.read.group           = "read_access_group_ssim"
  # config.permissions.read.individual      = "read_access_person_ssim"
  # config.permissions.edit.group           = "edit_access_group_ssim"
  # config.permissions.edit.individual      = "edit_access_person_ssim"
  #
  # config.permissions.embargo.release_date  = "embargo_release_date_dtsi"
  # config.permissions.lease.expiration_date = "lease_expiration_date_dtsi"
  #
  #
  # Specify the user model
  # config.user_model = 'User'

  config.user_key_field = Devise.authentication_keys.first
end
