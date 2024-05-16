# frozen_string_literal: true

# Creates counter metrics for a single tenant.
class GenerateCounterMetrics
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def self.generate_counter_metrics(ids: :all, limit: :all)
    fsq = "has_model_ssim: (#{Bulkrax.curation_concerns.join(' OR ')})"
    fsq += " AND id:(\"" + Array.wrap(ids).join('" OR "') + "\")" if ids.present? && ids != :all
    options = { fl: "id, has_model_ssim, resource_type_tesim, date_ssi, creator_tesim, publisher_tesim, title_tesim", method: :post }
    options[:rows] = limit if limit.is_a?(Numeric)
    ActiveFedora::SolrService.query(fsq, options).each do |work|
      work_type = work.fetch('has_model_ssim').first
      work_id = work.fetch('id')
      resource_type = work.fetch('resource_type_tesim').first
      year_of_publication = work.fetch('date_ssi')
      author = Sushi::AuthorCoercion.serialize(work.fetch('creator_tesim'))
      publisher = work.fetch('publisher_tesim')&.first if work['publisher_tesim']
      title = work.fetch('title_tesim')&.first if work['title_tesim']
      (0...90).each do |i|
        date = i.days.ago.to_date
        total_item_investigations = rand(1..10)
        total_item_requests = rand(1..10)

        Hyrax::CounterMetric.create!(
          worktype: work_type,
          work_id:,
          resource_type:,
          date:,
          year_of_publication:,
          author:,
          publisher:,
          title:,
          total_item_investigations:,
          total_item_requests:
        )
      end
    end
    message = "#{self.class}.generate_counter_metrics data for IDs = #{ids.inspect} with Limit = #{limit.inspect}."
    Rails.logger.info message
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
