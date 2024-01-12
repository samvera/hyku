# OVERRIDE Hyrax 5.0 to add AF methods to collection

Hyrax::AdministrativeSet.class_eval do
  include Hyrax::ArResource
end
