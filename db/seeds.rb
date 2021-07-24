# This data is loaded with the rake db:seed (or created alongside the db with db:setup).
# The bin/setup command will also invoke this
# Note: Fedora and Solr must be running for this to work
# Note: In a multitenant environment these actions must be taken only after the
#       solr & fedora for the tenant has been created so we keep
#       Apartment.seed_after_create = false (the default value)

unless Settings.multitenancy.enabled
  puts "\n== Creating single tenant resources"
  begin
    single_tenant_default = Account.find_by(cname: 'single.tenant.default')
    if single_tenant_default.blank?
      single_tenant_default = Account.new(name: 'Single Tenant', cname: 'single.tenant.default', tenant: 'single')
      CreateAccount.new(single_tenant_default).save
      single_tenant_default = single_tenant_default.reload
    end
  # Rescue from any errors during creation
  rescue
  end
  AccountElevator.switch!(single_tenant_default.cname)

  puts "\n== Creating default admin set"
  admin_set = AdminSet.find(AdminSet::DEFAULT_ID)

  puts "\n== Creating default collection types"
  Hyrax::CollectionType.find_or_create_default_collection_type
  Hyrax::CollectionType.find_or_create_admin_set_type

  puts "\n== Loading workflows"
  Hyrax::Workflow::WorkflowImporter.load_workflows
  errors = Hyrax::Workflow::WorkflowImporter.load_errors
  abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?

  puts "\n== Creating permission template"
  begin
    permission_template = admin_set.permission_template
  # If the permission template is missing we will need to run the creete service
  rescue
    Hyrax::AdminSetCreateService.new(admin_set: admin_set, creating_user: nil).create
  end

  puts "\n== Finished creating single tenant resources"
end


