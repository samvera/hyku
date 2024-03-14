# frozen_string_literal: true

require 'singleton'

class Reprocessor # rubocop:disable Metrics/ClassLength
  include Singleton

  SETTINGS = %w[header_lines batch_size current_location limit incremental_save log_dir].freeze

  attr_accessor(*SETTINGS)
  def initialize
    @header_lines = 1
    @batch_size   = 1000
    @current_location = 0
    @limit = nil
    @incremental_save = true
    @log_dir = 'tmp/imports'
    super
  end

  [:capture_ids, :process_ids].each do |method|
    define_singleton_method(method) do |*args|
      instance.send(method, *args)
    end
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
    state = JSON.parse(File.read("#{log_dir}/work_processor.json"))
    SETTINGS.each do |setting|
      instance.send("#{setting}=", state[setting])
    end
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

  def capture_work_ids
    Hyrax.config.query_index_from_valkyrie = false
    search = "has_model_ssim:(#{Bulkrax.curation_concerns.join(' OR ')})"
    caputre_with_solr(search)
  end

  def capture_file_set_ids
    Hyrax.config.query_index_from_valkyrie = false
    search = "has_model_ssim:(FileSet)"
    caputre_with_solr(search)
  end

  def capture_collection_ids
    Hyrax.config.query_index_from_valkyrie = false
    search = "has_model_ssim:(Collection)"
    caputre_with_solr(search)
  end

  def caputre_with_solr(search)
    count = Hyrax::SolrService.count(search)
    progress(count)
    while current_location < count
      break if limit && current_location >= limit
      ids = Hyrax::SolrService.query(search, fl: 'id', rows: batch_size, start: current_location)
      self.current_location += batch_size
      ids.each do |i|
        id_log.error(i['id'])
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
    with_id_lines do |lines|
      lines.each do |line|
        line_counter += 1
        if line_counter < current_location
          progress.increment
          next
        end
        break if limit && current_location >= limit
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
      break if limit && current_location >= limit
    end
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

  def lambda_index
    @lambda_save ||= lambda { |line, _progress|
      id = line.strip
      w = Hyrax.query_service.find_by(id:)
      Hyrax.index_adapter.save(resource: w)
    }
  end

  def lambda_print
    @lambda_save ||= lambda { |line, progress|
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
