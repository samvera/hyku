# frozen_string_literal: true

# Upload solr configuration from the local filesystem into the zookeeper configs path for solr
class SolrConfigUploader
  attr_reader :collection_path

  ##
  # Build a new SolrConfigUploader using the application-wide settings
  def self.default
    new(Settings.solr.configset)
  end

  def initialize(collection_path)
    @collection_path = collection_path
  end

  def upload(upload_directory)
    with_client do |zk|
      salient_files(upload_directory).each do |file|
        zk.create(zookeeper_path_for_file(file), file.read, or: :set)
      end
    end
  end

  def delete_all
    with_client do |zk|
      zk.rm_rf(zookeeper_path)
    end
  end

  def get(path)
    with_client do |zk|
      zk.get(zookeeper_path(path)).first
    end
  end

  private

    def zookeeper_path_for_file(file)
      zookeeper_path(File.basename(file.path))
    end

    def zookeeper_path(*path)
      "/#{([collection_path] + path).compact.join('/')}"
    end

    def salient_files(config_dir)
      return to_enum(:salient_files, config_dir) unless block_given?

      Dir.new(config_dir).each do |file_name|
        full_path = File.expand_path(file_name, config_dir)

        next unless File.file? full_path

        yield File.new(full_path)
      end
    end

    def with_client(&block)
      ensure_chroot!

      ZK.open(connection_str, &block)
    end

    def connection_str
      Settings.zookeeper.connection_str
    end

    def ensure_chroot!
      raise ArgumentError, 'Zookeeper connection string must include a chroot path' unless connection_str =~ %r{/[^/]}
    end
end
