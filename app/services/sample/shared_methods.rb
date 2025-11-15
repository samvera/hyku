# frozen_string_literal: true

module Sample
  module SharedMethods # rubocop:disable Metrics/ModuleLength
    attr_accessor :admin_set, :user
    attr_reader :tenant_name, :sample_files_dir, :sample_data, :quantity

    def initialize(tenant_name, quantity = 50)
      @tenant_name = tenant_name
      @quantity = quantity.to_i
      @sample_files_dir = Rails.root.join('db', 'seeds', 'sample')
      @sample_data = {}
      @user = nil
      @admin_set = nil
    end

    private

    def confirm_cleanup # rubocop:disable Metrics/AbcSize
      # Skip confirmation if CONFIRM environment variable is set to 'true'
      return true if ENV['CONFIRM']&.downcase == 'true'

      Rails.logger.debug "\n" + "=" * 60
      Rails.logger.debug "WARNING: DESTRUCTIVE OPERATION"
      Rails.logger.debug "=" * 60
      Rails.logger.debug "This will DELETE works, collections, and file sets from tenant '#{tenant_name}'"
      Rails.logger.debug "that match the following title patterns:"
      Rails.logger.debug "  - Collections with titles like 'Collection N: ...'"
      Rails.logger.debug "  - Images with titles like 'Image N: ...'"
      Rails.logger.debug "  - Generic Works with titles like 'Generic Work N: ...'"
      Rails.logger.debug "  - File Sets with titles like 'FileSet N: ...'"
      Rails.logger.debug "\nThis action CANNOT be undone!"
      Rails.logger.debug "=" * 60
      Rails.logger.debug "\nType 'yes' to continue or anything else to abort: "

      response = $stdin.gets.chomp
      confirmed = response.casecmp('yes').zero?

      unless confirmed
        Rails.logger.debug "Operation aborted."
        return false
      end

      Rails.logger.debug "Proceeding with cleanup..."
      true
    end

    def validate_and_switch_tenant
      account = Account.find_by(name: tenant_name)
      if account.nil?
        Rails.logger.debug "ERROR: Tenant '#{tenant_name}' not found!"
        Rails.logger.debug "Available tenants:"
        Account.find_each { |acc| Rails.logger.debug "  - #{acc.name}" }
        raise "Tenant not found"
      end

      Rails.logger.debug "Switching to tenant: #{tenant_name}"
      AccountElevator.switch!(tenant_name)
    end

    def load_sample_data # rubocop:disable Metrics/AbcSize
      require 'csv'

      Rails.logger.debug "Loading sample data from CSV files..."
      @sample_data = {
        titles: CSV.read(sample_files_dir.join('sample_titles.csv'), headers: true)['title'],
        descriptions: CSV.read(sample_files_dir.join('sample_descriptions.csv'), headers: true)['description'],
        creators: CSV.read(sample_files_dir.join('sample_creators.csv'), headers: true)['creator'].map { |creator| [creator] },
        subjects: load_subjects_from_csv,
        files: {
          pdf: ['sample-report.pdf'],
          image: ['landscape_hires_4000x2667_6.83mb.jpg'],
          audio: ['mp3_44100Hz_128kbps_stereo.mp3', 'm4a_48000Hz_256kbps_stereo.m4a'],
          video: ['big_buck_bunny_720p_10mb.mp4']
        }
      }

      Rails.logger.debug "Using sample files:"
      @sample_data[:files].each do |type, files|
        Rails.logger.debug "  #{type.upcase}: #{files.join(', ')}"
      end

      Rails.logger.debug "Loaded #{@sample_data[:titles].length} titles, " \
                         "#{@sample_data[:descriptions].length} descriptions, " \
                         "#{@sample_data[:creators].length} creators, " \
                         "#{@sample_data[:subjects].length} subject sets"
      Rails.logger.debug ""
    end

    def load_subjects_from_csv
      subjects_csv = CSV.read(sample_files_dir.join('sample_subjects.csv'), headers: true)
      subjects_csv.map do |row|
        [row['subject1'], row['subject2'], row['subject3']].compact.reject(&:empty?)
      end
    end

    def setup_dependencies
      self.user = User.first
      Rails.logger.debug "Creating #{quantity} sample works for tenant '#{tenant_name}'..."
    end

    def select_file_for_work(index)
      case index % 4
      when 0 then sample_data[:files][:pdf].first
      when 1 then sample_data[:files][:image].first
      when 2 then sample_data[:files][:audio].sample
      when 3 then sample_data[:files][:video].first
      end
    end

    def setup_job_configuration
      @original_use_valkyrie = Hyrax.config.use_valkyrie?
      @original_hyrax_queue = ENV['HYRAX_ACTIVE_JOB_QUEUE']
      ENV['HYRAX_ACTIVE_JOB_QUEUE'] = 'async'
      @original_queue_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new
    end

    def restore_job_configuration
      Hyrax.config.use_valkyrie = @original_use_valkyrie
      ENV['HYRAX_VALKYRIE'] = @original_use_valkyrie.to_s
      ENV['HYRAX_ACTIVE_JOB_QUEUE'] = @original_hyrax_queue
      ActiveJob::Base.queue_adapter = @original_queue_adapter
    end

    # rubocop:disable Metrics/AbcSize
    def print_completion_summary(collections, images, generic_works, oers, total)
      object_type = self.class.name.include?('Valkyrie') ? 'VALKYRIE' : 'ACTIVEFEDORA'
      Rails.logger.debug "\n" + "=" * 60
      Rails.logger.debug "SAMPLE #{object_type} DATA CREATION COMPLETE"
      Rails.logger.debug "=" * 60
      Rails.logger.debug "Tenant: #{tenant_name}"
      Rails.logger.debug "Created #{collections.length} Collections"
      Rails.logger.debug "Created #{images.length} Images"
      Rails.logger.debug "Created #{generic_works.length} Generic Works"
      Rails.logger.debug "Created #{oers.length} OERs"
      Rails.logger.debug "Total: #{total} works created"
      Rails.logger.debug "=" * 60
      # rubocop:enable Metrics/AbcSize
    end

    def print_cleanup_summary(counts, total) # rubocop:disable Metrics/AbcSize
      object_type = self.class.name.include?('Valkyrie') ? 'VALKYRIE' : 'ACTIVEFEDORA'
      Rails.logger.debug "\n" + "=" * 60
      Rails.logger.debug "SAMPLE #{object_type} DATA CLEANUP COMPLETE"
      Rails.logger.debug "=" * 60
      Rails.logger.debug "Tenant: #{tenant_name}"
      Rails.logger.debug "Removed #{counts[:collections]} Collections"
      Rails.logger.debug "Removed #{counts[:images]} Images"
      Rails.logger.debug "Removed #{counts[:generic_works]} Generic Works"
      Rails.logger.debug "Removed #{counts[:file_sets]} FileSets"
      Rails.logger.debug "Total: #{total} works removed"
      Rails.logger.debug "=" * 60
    end

    def add_to_random_collection(work, collections)
      return unless collections.any?

      collection = collections.sample
      if work.respond_to?(:member_of_collections)
        # ActiveFedora approach
        work.member_of_collections << collection
      else
        # Valkyrie approach - set collection membership on the work
        work.member_of_collection_ids = [collection.id]
        Hyrax.persister.save(resource: work)
      end
    end
  end
end
