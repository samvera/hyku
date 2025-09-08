# frozen_string_literal: true

namespace :discogs do
  desc "Set up Discogs integration by generating required YAML files"
  task setup: :environment do
    puts "🎵 Setting up Discogs integration..."

    # Check if files already exist
    formats_file = Rails.root.join('config', 'discogs-formats.yml')
    genres_file = Rails.root.join('config', 'discogs-genres.yml')

    if formats_file.exist? && genres_file.exist?
      puts "✅ Discogs configuration files already exist:"
      puts "   - #{formats_file}"
      puts "   - #{genres_file}"
      puts ""
      puts "ℹ️  If you need to regenerate them, delete the existing files and run this task again."
      return
    end

    puts "📝 Generating Discogs configuration files..."

    begin
      # Generate the Discogs YAML files
      system("bundle exec rails generate qa:discogs")

      if formats_file.exist? && genres_file.exist?
        puts "✅ Successfully generated Discogs configuration files:"
        puts "   - #{formats_file}"
        puts "   - #{genres_file}"
        puts ""
        puts "🎯 Next steps:"
        puts "   1. Set up your Discogs Personal Access Token in Account Settings"
        puts "   2. Restart your application"
        puts "   3. Test the Music Release field in your forms"
        puts ""
        puts "📋 For deployment:"
        puts "   - These files should NOT be committed to version control"
        puts "   - Run 'bundle exec rails generate qa:discogs' on each server"
        puts "   - Files contain format/genre mappings derived from Discogs API"
      else
        puts "❌ Failed to generate Discogs configuration files"
        puts "   Please run manually: bundle exec rails generate qa:discogs"
      end

    rescue => e
      puts "❌ Error generating Discogs files: #{e.message}"
      puts "   Please run manually: bundle exec rails generate qa:discogs"
    end
  end

  desc "Check Discogs setup status"
  task status: :environment do
    # Suppress verbose output
    ActiveRecord::Base.logger.level = Logger::WARN

    puts "🎵 Checking Discogs setup status..."

    formats_file = Rails.root.join('config', 'discogs-formats.yml')
    genres_file = Rails.root.join('config', 'discogs-genres.yml')

    puts ""
    puts "📁 Configuration Files:"
    puts "   discogs-formats.yml: #{formats_file.exist? ? '✅ Present' : '❌ Missing'}"
    puts "   discogs-genres.yml: #{genres_file.exist? ? '✅ Present' : '❌ Missing'}"

    puts ""
    puts "🏢 Tenant Configuration:"

    # Check each tenant for Discogs token
    Account.find_each do |account|
      Account.switch!(account)
      token_status = account.respond_to?(:discogs_user_token) && account.discogs_user_token.present? ? '✅ Configured' : '❌ Not configured'
      puts "   #{account.name}: #{token_status}"
    end

    puts ""
    if formats_file.exist? && genres_file.exist?
      puts "🎯 Discogs integration is ready!"
      puts "   Make sure each tenant has a Discogs Personal Access Token configured."
    else
      puts "⚠️  Discogs integration is not ready."
      puts "   Run: bundle exec rake discogs:setup"
    end
  end

  desc "Test Discogs API connectivity"
  task test: :environment do
    # Suppress verbose output
    ActiveRecord::Base.logger.level = Logger::WARN
    puts "🎵 Testing Discogs API connectivity..."

    # Check if required files exist
    formats_file = Rails.root.join('config', 'discogs-formats.yml')
    genres_file = Rails.root.join('config', 'discogs-genres.yml')

    unless formats_file.exist? && genres_file.exist?
      puts "❌ Discogs configuration files are missing"
      puts "   Run: bundle exec rake discogs:setup"
      abort
    end

    # Test with a tenant that has a token
    test_account = nil
    Account.find_each do |account|
      Account.switch!(account)
      if account.respond_to?(:discogs_user_token) && account.discogs_user_token.present?
        test_account = account
        break
      end
    end

    unless test_account
      puts "❌ No tenant has a Discogs token configured"
      puts "   Configure a Discogs Personal Access Token in Account Settings"
      abort
    end

    puts "🧪 Testing with tenant: #{test_account.name}"

    begin
      # Test the Discogs API
      authority = Qa::Authorities::Discogs::GenericAuthority.new('release')
      results = authority.search('abbey', nil)

      if results.any?
        puts "✅ Discogs API is working!"
        puts "   Found #{results.length} results for 'abbey'"
        puts "   Sample result: #{results.first['label']}"
      else
        puts "⚠️  Discogs API responded but returned no results"
        puts "   This might be normal - try a different search term"
      end

    rescue => e
      puts "❌ Discogs API test failed: #{e.message}"
      puts "   Check your Discogs Personal Access Token"
    end
  end
end
