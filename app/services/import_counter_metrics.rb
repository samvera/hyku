# frozen_string_literal: true

# Import counter views and downloads for a given tenant
# Currently, this only imports the first resource type. Additional work would need to be done for works with multiple resource types.
# The resource_type field in the counter_metrics table is single value and not an array.
class ImportCounterMetrics
  # rubocop:disable Metrics/MethodLength, Metrics/BlockLength
  def self.import_investigations(csv_path)
    CSV.foreach(csv_path, headers: true) do |row|
      work = ActiveFedora::Base.where(bulkrax_identifier_tesim: row['eprintid']).first
      next if work.nil?
      worktype = work.class
      work_id = work.id
      resource_type = work.resource_type&.first
      date = row['datestamp']
      year_of_publication = work.date
      author = Sushi::AuthorCoercion.serialize(work.creator)
      publisher = work.publisher&.first
      title = work.title&.first
      total_item_investigations = row['count']
      counter_investigation = Hyrax::CounterMetric.find_by(work_id:, date:)
      if counter_investigation.present?
        counter_investigation.update(
          worktype:,
          work_id:,
          resource_type:,
          date:,
          total_item_investigations:,
          year_of_publication:,
          author:,
          publisher:,
          title:
        )
      else
        Hyrax::CounterMetric.create!(
          worktype:,
          work_id:,
          resource_type:,
          date:,
          total_item_investigations:,
          year_of_publication:,
          author:,
          publisher:,
          title:
        )
      end
    end
  end

  def self.import_requests(csv_path)
    CSV.foreach(csv_path, headers: true) do |row|
      work = ActiveFedora::Base.where(bulkrax_identifier_tesim: row['eprintid']).first
      next if work.nil?
      worktype = work.class
      work_id = work.id
      resource_type = work.resource_type.first
      date = row['datestamp']
      year_of_publication = work.date
      author = Sushi::AuthorCoercion.serialize(work.creator)
      publisher = work.publisher&.first
      title = work.title&.first
      total_item_requests = row['count']
      counter_request = Hyrax::CounterMetric.find_by(work_id:, date:)
      if counter_request.present?
        counter_request.update(
          worktype:,
          work_id:,
          resource_type:,
          date:,
          total_item_requests:,
          year_of_publication:,
          author:,
          publisher:,
          title:
        )
      else
        Hyrax::CounterMetric.create!(
          worktype:,
          work_id:,
          resource_type:,
          date:,
          total_item_requests:,
          year_of_publication:,
          author:,
          publisher:,
          title:
        )
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/BlockLength
end
