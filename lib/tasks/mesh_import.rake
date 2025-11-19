# frozen_string_literal: true
namespace :mesh do
  desc "Import MeSH data for a specific tenant"
  task :import_tenant, [:tenant_name, :mesh_file] => :environment do |_t, args|
    # Suppress verbose output
    ActiveRecord::Base.logger.level = Logger::WARN

    tenant_name = args[:tenant_name]
    mesh_file = args[:mesh_file] || 'mesh_terms.txt'

    if tenant_name.blank?
      puts "❌ Error: Tenant name is required"
      puts "Usage: rake mesh:import_tenant[tenant_name,mesh_file]"
      puts "Example: rake mesh:import_tenant[dev,mesh_terms.txt]"
      exit 1
    end

    unless File.exist?(mesh_file)
      puts "❌ Error: MeSH file not found: #{mesh_file}"
      puts "Please ensure the file exists and try again"
      exit 1
    end

    puts "🚀 Starting MeSH import for tenant: #{tenant_name}"
    puts "📁 Using file: #{mesh_file}"

    # Switch to the specified tenant
    begin
      account = Account.find_by(name: tenant_name)
      if account.nil?
        puts "❌ Error: Tenant '#{tenant_name}' not found"
        puts "Available tenants: #{Account.pluck(:name).join(', ')}"
        exit 1
      end
      Account.switch!(account)
      puts "✅ Switched to tenant: #{account.name}"
    rescue => e
      puts "❌ Error switching to tenant: #{e.message}"
      exit 1
    end

    # Check if MeSH authority already exists
    mesh_authority = Qa::LocalAuthority.find_by(name: 'mesh')
    if mesh_authority
      puts "⚠️  MeSH authority already exists. Clearing existing entries..."
      mesh_authority.local_authority_entries.destroy_all
    else
      puts "📝 Creating MeSH authority..."
      mesh_authority = Qa::LocalAuthority.create!(name: 'mesh')
    end

    # Import MeSH terms
    puts "📖 Reading MeSH terms from #{mesh_file}..."
    terms = File.readlines(mesh_file).map(&:strip).reject(&:blank?)
    puts "📊 Found #{terms.length} terms to import"

    # Import in batches to avoid memory issues
    batch_size = 1000
    imported_count = 0

    terms.each_slice(batch_size) do |batch|
      entries = batch.map do |term|
        {
          local_authority_id: mesh_authority.id,
          label: term,
          uri: "http://id.nlm.nih.gov/mesh/#{term.gsub(/[^a-zA-Z0-9]/, '')}",
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # Using insert_all for performance with large datasets
      # rubocop:disable Rails/SkipsModelValidations
      Qa::LocalAuthorityEntry.insert_all(entries)
      # rubocop:enable Rails/SkipsModelValidations
      imported_count += batch.length
      print "📈 Imported #{imported_count}/#{terms.length} terms\r"
    end

    puts "\n✅ MeSH import complete!"
    puts "📊 Total terms imported: #{imported_count}"
    puts "🏥 MeSH authority ID: #{mesh_authority.id}"

    # Verify the import
    final_count = mesh_authority.local_authority_entries.count
    puts "🔍 Verification: #{final_count} entries in database"

    if final_count.positive?
      puts "✅ Import successful!"
      puts "🧪 Test with: Qa::LocalAuthorityEntry.where(local_authority_id: #{mesh_authority.id}).where(\"label ILIKE ?\", \"%diabetes%\").pluck(:label)"
    else
      puts "❌ Import failed - no entries found in database"
      exit 1
    end
  end

  desc "List all tenants and their MeSH data status"
  task :status => :environment do
    # Suppress verbose output
    ActiveRecord::Base.logger.level = Logger::WARN

    puts "🏢 MeSH Import Status Report"
    puts "=" * 50

    Account.find_each do |account|
      puts "\n📋 Tenant: #{account.name}"

      # Switch to this tenant
      Account.switch!(account)

      # Check MeSH authority
      mesh_authority = Qa::LocalAuthority.find_by(name: 'mesh')
      if mesh_authority
        entry_count = mesh_authority.local_authority_entries.count
        puts "  ✅ MeSH authority exists"
        puts "  📊 Entries: #{entry_count}"

        if entry_count.positive?
          # Show a few sample terms
          sample_terms = mesh_authority.local_authority_entries.limit(3).pluck(:label)
          puts "  🔍 Sample terms: #{sample_terms.join(', ')}"
        end
      else
        puts "  ❌ No MeSH authority found"
      end
    end

    puts "\n" + "=" * 50
    puts "💡 To import MeSH for a tenant: rake mesh:import_tenant[tenant_name,mesh_file]"
  end

  desc "Clear MeSH data for a specific tenant"
  task :clear_tenant, [:tenant_name] => :environment do |_t, args|
    # Suppress verbose output
    ActiveRecord::Base.logger.level = Logger::WARN

    tenant_name = args[:tenant_name]

    if tenant_name.blank?
      puts "❌ Error: Tenant name is required"
      puts "Usage: rake mesh:clear_tenant[tenant_name]"
      exit 1
    end

    begin
      account = Account.find_by(name: tenant_name)
      if account.nil?
        puts "❌ Error: Tenant '#{tenant_name}' not found"
        exit 1
      end
      Account.switch!(account)

      mesh_authority = Qa::LocalAuthority.find_by(name: 'mesh')
      if mesh_authority
        entry_count = mesh_authority.local_authority_entries.count
        mesh_authority.destroy
        puts "✅ Cleared #{entry_count} MeSH entries for tenant: #{tenant_name}"
      else
        puts "ℹ️  No MeSH data found for tenant: #{tenant_name}"
      end
    rescue => e
      puts "❌ Error: #{e.message}"
      exit 1
    end
  end

  desc "Test MeSH search functionality"
  task :test_search, [:tenant_name] => :environment do |_t, args|
    # Suppress verbose output
    ActiveRecord::Base.logger.level = Logger::WARN

    tenant_name = args[:tenant_name] || 'dev'

    begin
      account = Account.find_by(name: tenant_name)
      if account.nil?
        puts "❌ Error: Tenant '#{tenant_name}' not found"
        exit 1
      end
      Account.switch!(account)

      mesh_authority = Qa::LocalAuthority.find_by(name: 'mesh')
      if mesh_authority.nil?
        puts "❌ Error: No MeSH authority found for tenant: #{tenant_name}"
        exit 1
      end

      # Test searches
      test_terms = ['diabetes', 'cancer', 'heart', 'brain']

      puts "🧪 Testing MeSH search for tenant: #{tenant_name}"
      puts "=" * 50

      test_terms.each do |term|
        results = mesh_authority.local_authority_entries.where("label ILIKE ?", "%#{term}%").limit(5).pluck(:label)
        if results.any?
          puts "✅ '#{term}': #{results.join(', ')}"
        else
          puts "❌ '#{term}': No results found"
        end
      end

    rescue => e
      puts "❌ Error: #{e.message}"
      exit 1
    end
  end
end
