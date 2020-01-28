# This data is loaded with the rake db:seed (or created alongside the db with db:setup).
# The bin/setup command will also invoke this
# Note: Fedora and Solr must be running for this to work
# Note: In a multitenant environment these actions must be taken only after the
#       solr & fedora for the tenant has been created so we keep
#       Apartment.seed_after_create = false (the default value)

puts "\n== Uploading the solr config to zookeeper"
Rake::Task['zookeeper:upload'].invoke

puts "\n== Loading workflows"
Hyrax::Workflow::WorkflowImporter.load_workflows
errors = Hyrax::Workflow::WorkflowImporter.load_errors
abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?

puts "\n== Creating default collection types"
Rake::Task['hyrax:default_collection_types:create'].invoke

unless Settings.multitenancy.enabled
  puts "\n== Creating single tenant resources"
  single_tenant_default = Account.new(name: 'Single Tenant', cname: "single.#{Settings.multitenancy.default_host}", tenant: 'single')
  CreateAccount.new(single_tenant_default).save

  puts "\n== Creating default admin set"
  Rake::Task['hyrax:default_admin_set:create'].invoke
end

