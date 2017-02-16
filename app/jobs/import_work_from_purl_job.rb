require 'stanford'
# Import works from Purl/stacks services at Stanford
#
# Example usage:
#       log = Hyrax::Operation.create!(user: current_user,
#                                      operation_type: "Import Purl Metadata")
#       ImportWorkFromPurlJob.perform_later(current_user,
#                                           'abcd1234xxxx',
#                                           log)
class ImportWorkFromPurlJob < ActiveJob::Base
  queue_as :ingest

  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  # @param [User] user
  # @param [String] druid
  # @param [Hyrax::Operation] log
  def perform(user, druid, log)
    xml = Stanford::Importer::PurlRetriever.get(druid)
    parser = Stanford::Importer::PurlParser.new(xml)
    attributes = process_attributes(parser.attributes)
    model = model_to_create(attributes)

    CreateWorkJob.perform_later(user, model, attributes, log)
  rescue Faraday::ResourceNotFound
    Rails.logger.error "Unable to fetch #{druid} from purl."
  end

  private

    def process_attributes(attributes)
      # We're pruning off :form_of_work, :record_origin, :created_attributes, :identifiers
      attributes = attributes.slice(*attributes_to_keep)
      # rename :location to :based_near
      attributes[:based_near] = attributes.delete(:location)

      process_collection(attributes)
      filenames = attributes.delete(:files)
      attributes[:remote_files] = filenames.map do |name|
        { url: "https://stacks.stanford.edu/file/druid:#{attributes[:id]}/#{name}",
          file_name: name }
      end

      attributes
    end

    class_attribute :attributes_to_keep
    self.attributes_to_keep = [:title,
                               :description,
                               :subject,
                               :language,
                               :resource_type,
                               :location,
                               :rights,
                               :visibility,
                               :id,
                               :collection,
                               :files]

    def process_collection(attributes)
      # rename :collection to :member_of_collection_ids
      collection = attributes.delete(:collection)

      # Workaround for ActiveFedora #1186
      id = collection[:id]
      begin
        retries ||= 0
        Collection.create!(collection) unless Collection.exists?(id)
      rescue Ldp::Conflict => e
        ## Another process has likely beat us to the punch. Wait a bit and try again.
        sleep(3)
        retry if (retries += 1) < 3
        raise e
      end
      attributes[:member_of_collection_ids] = [id]
    end

    # Override this method if you have a different rubric for choosing the model
    # @param [Hash] attributes
    # @return String the model to create
    def model_to_create(attributes)
      Hyrax.config.model_to_create.call(attributes)
    end
end
