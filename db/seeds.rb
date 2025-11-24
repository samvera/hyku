# This data is loaded with the rake db:seed (or created alongside the db with db:setup).
# The bin/setup command will also invoke this
# Note: Fedora and Solr must be running for this to work
# Note: In a multitenant environment these actions must be taken only after the
#       solr & fedora for the tenant has been created so we keep
#       Apartment.seed_after_create = false (the default value)

unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MULTITENANT', false))
  puts "\n== Creating single tenant resources"
  single_tenant_default = Account.find_by(cname: 'single.tenant.default')
  if single_tenant_default.blank?
    single_tenant_default = Account.new(name: 'Single Tenant', cname: 'single.tenant.default', tenant: SecureRandom.uuid, is_public: true)
    CreateAccount.new(single_tenant_default).save
    raise "Account creation failed for #{single_tenant_default.errors.full_messages}" unless single_tenant_default.valid?
    single_tenant_default = single_tenant_default.reload
  end
  AccountElevator.switch!(single_tenant_default.cname)

  puts "\n== Creating default admin set with permission template"
  Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id

  puts "\n== Creating default collection types"
  Hyrax::CollectionType.find_or_create_default_collection_type
  Hyrax::CollectionType.find_or_create_admin_set_type

  puts "\n== Loading workflows"
  Hyrax::Workflow::WorkflowImporter.load_workflows
  errors = Hyrax::Workflow::WorkflowImporter.load_errors
  abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?

  puts "\n== Finished creating single tenant resources"
end

Account.find_each do |account|
  Apartment::Tenant.switch!(account.tenant)
  next if Site.instance.available_works.present?
  Site.instance.available_works = Hyrax.config.registered_curation_concern_types
  Site.instance.save

  if Hyrax.config.flexible?
    puts "\n== Loading basic metadata profile"
    Hyrax::RequiredDataSeeders::FlexibleProfileSeeder.generate_seeds(logger: Logger.new(STDOUT))
  end
end

if ENV['INITIAL_ADMIN_EMAIL'] && ENV['INITIAL_ADMIN_PASSWORD']
  reset!
  u = User.find_or_create_by(email: ENV['INITIAL_ADMIN_EMAIL']) do |u|
    u.password = ENV['INITIAL_ADMIN_PASSWORD']
    u.add_role(:superadmin)
  end
end
