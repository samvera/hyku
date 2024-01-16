# frozen_string_literal: true

# OVERRIDE Hyrax 5.0 to add AF methods to collection

Hyrax::AdministrativeSet.class_eval do
  include Hyrax::ArResource
  include Hyrax::Permissions::Readable
end
