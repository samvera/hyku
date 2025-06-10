# frozen_string_literal: true

require 'singleton'
require 'ruby-progressbar'

## Reprocessor for iterating through large sets of ids
# There are two steps for any reprocessing:
# 1. Store all the ids for processing to a ids.log file.
# 2. Run a lambda against every id.
# No matter whether it is the first run or not, a run of the Reprocessor should always start with Reprocessor.load('tmp/imports/SOME_UNIQUE_NAME')
# This creates a context for the Reprocessor to run. After that, calling Reprocessor.capture_ids (or capture_work_ids, capture_file_set_ids or capture collection_ids)
# will record all the ids in a file.
# Finally, once all the ids are split, calling Reprocessor.process_ids with a lambda (like Reprocessor.process_ids(Reprocessor.save)) to call the process on each item
# At any point, the process can be stopped (or killed) and then resumed by doing Reprocessor.load(SAME_PATH) and then calling #process_ids again.
class Reprocessor # rubocop:disable Metrics/ClassLength
  include Singleton

  SETTINGS = %w[header_lines batch_size single_batch current_location limit incremental_save log_dir].freeze

  attr_accessor(*SETTINGS)
  attr_writer :error_log, :id_line_size, :id_log, :id_path

  def initialize
    @header_lines = 1
    @batch_size   = 1000
    @single_batch = false
    @current_location = 0
    @limit = nil
    @incremental_save = true
    @log_dir = 'tmp/imports'
    super
  end

  # Missing methods will be delegated to `instance` if an implementation is available.
  # Else `NoMethodError` will be raised via call to `super`
  def self.method_missing(method_name, *args)
    if instance.respond_to? method_name
      # rubocop:disable Rails/Output
      puts "** Defining new method: '#{method_name}'"
      # rubocop:enable Rails/Output
      (class << self; self; end).instance_eval do
        define_method(method_name) do |*method_args|
          instance.send(method_name, *method_args)
        end
      end
      instance.send(method_name, *args)
    else
      super
    end
  end

  def self.respond_to_missing?(method_name, include_private = false)
    instance.respond_to?(method_name) || super
  end

  SETTINGS.each do |method|
    define_singleton_method(method) do |*args|
      instance.send(method, *args)
    end

    define_singleton_method("#{method}=") do |*args|
      instance.send("#{method}=", *args)
    end
  end

  def self.load(log_dir = Rails.root.join('tmp', 'imports').to_s)
    FileUtils.mkdir_p(log_dir)
    state = JSON.parse(File.read("#{log_dir}/work_processor.json"))
    SETTINGS.each do |setting|
      instance.send("#{setting}=", state[setting])
    end
    instance.error_log = nil
    instance.id_line_size = nil
    instance.id_log = nil
    instance.id_path = nil
  rescue Errno::ENOENT
    puts 'no save file to load' # rubocop:disable Rails/Output
    instance.log_dir = log_dir
  end

  def self.save
    state = {}
    SETTINGS.each do |setting|
      state[setting] = instance.send(setting)
    end
    File.write("#{instance.log_dir}/work_processor.json", state.to_json)
  end

  def capture_ids
    capture_collection_ids
    capture_work_ids
    capture_file_set_ids
  end

  def capture_work_ids
    Hyrax.config.query_index_from_valkyrie = false
    search = "has_model_ssim:(#{Bulkrax.curation_concerns.join(' OR ')})"
    capture_with_solr(search)
    self.current_location = 0
  end

  def capture_file_set_ids
    Hyrax.config.query_index_from_valkyrie = false
    search = "has_model_ssim:(FileSet)"
    capture_with_solr(search)
    self.current_location = 0
  end

  def capture_collection_ids
    Hyrax.config.query_index_from_valkyrie = false
    search = "has_model_ssim:(Collection OR AdminSet)"
    capture_with_solr(search)
    self.current_location = 0
  end

  def capture_with_solr(search)
    count = Hyrax::SolrService.count(search)
    progress(count)
    while current_location < count
      break if limit && current_location >= limit
      ids = Hyrax::SolrService.query(search, fl: 'id,fedora_id_ssi', rows: batch_size, start: current_location)
      self.current_location += batch_size
      ids.each do |i|
        id = i['fedora_id_ssi'] || i['id']
        id_log.error(id)
      end
      progress.progress = [self.current_location, count].min
      Reprocessor.save if incremental_save
    end
  end

  def capture_bulkrax_entry_ids(query)
    count = query.count
    progress(count)
    i = 0
    query.find_each do |entry|
      next if i < self.current_location
      break if limit && i >= limit
      id_log.error(entry.id)
      progress.increment
      i += 1
      self.current_location += 1
      Reprocessor.save if incremental_save
    end
  end

  def process_ids(lamb)
    progress(id_line_size)
    line_counter = 0
    current_limit(reset: true)
    with_id_lines do |lines|
      lines.each do |line|
        line_counter += 1
        if line_counter < current_location
          progress.increment
          next
        end
        break if current_limit && current_location >= current_limit
        begin
          lamb.call(line, progress)
        rescue => e
          error(line, e)
        end
        self.current_location += 1
        progress.increment
        Reprocessor.save if incremental_save
      end
      # double break to get out of the lazy loop
      break if current_limit && current_location >= current_limit
    end
  end

  def current_limit(reset: false)
    return @current_limit if @current_limit && !reset
    @current_limit = single_batch ? current_location + batch_size : limit
  end

  def error(line, exception)
    msg = "#{line} - #{exception.message[0..200]}"
    error_log.error(msg)
  end

  def error_log
    @error_log ||= ActiveSupport::Logger.new("#{log_dir}/error.log")
  end

  def id_path
    @id_path ||= "#{log_dir}/ids.log"
  end

  def id_log
    @id_log ||= ActiveSupport::Logger.new(id_path)
  end

  def id_line_size
    @id_line_size ||= `wc -l #{id_path}`.split.first.to_i
  end

  def with_id_lines
    File.open(id_path) do |file|
      file.lazy.drop(header_lines).each_slice(batch_size) do |lines|
        yield lines
      end
    end
  end

  def lambda_create_relationships
    @lambda_create_relationships ||= lambda { |line, _progress|
      id = line.strip
      e = Bulkrax::Entry.find(id)
      ::SEEN ||= [] # rubocop:disable Style/MutableConstant
      unless ::SEEN.include?(e.importer.id)
        ::SEEN << e.importer.id
        e.parser.create_parent_child_relationships
      end
    }
  end

  def lambda_save
    @lambda_save ||= lambda { |line, _progress|
      id = line.strip
      w = Hyrax.query_service.find_by(id:)
      w.save
    }
  end

  def lambda_migrate_resources
    @lambda_migrate_resources = lambda { |line, _progress|
      id = line.strip
      MigrateResourcesJob.perform_later(ids: [id])
    }
  end

  # because this takes an arg, we dont memoize
  def lambda_job(_job_klass)
    @lambda_job = lambda { |line, _progress, job_klass|
      id = line.strip
      job_klass.perform_later(id)
    }
  end

  def lambda_af_index
    @lambda_af_index ||= lambda { |line, _progress|
      id = line.strip
      w = ActiveFedora::Base.find(id)
      w.update_index
    }
  end

  def lambda_index
    @lambda_index ||= lambda { |line, _progress|
      id = line.strip
      w = Hyrax.query_service.find_by(id:)
      Hyrax.index_adapter.save(resource: w)
    }
  end

  def lambda_print
    @lambda_print ||= lambda { |line, progress|
      id = line.strip
      progress.log id
    }
  end

  def progress(total = nil)
    if total
      @progress = ProgressBar.create(total:,
                                     format: "%a %b\u{15E7}%i %c/%C %p%% %t",
                                     progress_mark: ' ',
                                     remainder_mark: "\u{FF65}")
    else
      @progress
    end
  end
end
