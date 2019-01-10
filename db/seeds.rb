# This data is loaded with the rake db:seed (or created alongside the db with db:setup).
# The bin/setup command will also invoke this
# Note: Fedora and Solr must be running for this to work
# Note: In a multitenant environment these actions must be taken only after the
#       solr & fedora for the tenant has been created so we keep
#       Apartment.seed_after_create = false (the default value)

puts "\n== Creating default admin set"
AdminSet.find_or_create_default_admin_set_id

puts "\n== Loading workflows"
Hyrax::Workflow::WorkflowImporter.load_workflows
errors = Hyrax::Workflow::WorkflowImporter.load_errors
abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?

user = User.where(email: 'rob@notch8.com').first_or_create do |u|
  u.password = 'testing123'
  u.display_name = "Rob"
end
user.add_role :superadmin unless user.has_role? :superadmin
