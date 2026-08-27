# frozen_string_literal: true

module IndexesControlledLabels
  delegate :controlled_vocabulary_service_for, to: 'ApplicationController.helpers', private: true

  private

  def relabel_controlled_values(solr_doc)
    return solr_doc unless Hyrax.config.flexible?

    controlled_index_keys.each do |key|
      next unless solr_doc.key?(key)

      solr_doc[key] = Array(solr_doc[key]).map { |value| authority_label(services_for(key), value) }
    end

    solr_doc
  end

  def controlled_index_keys
    controlled_properties.flat_map(&:first).uniq
  end

  def services_for(key)
    controlled_properties.filter_map { |indexing_keys, service| service if indexing_keys.include?(key) }.uniq
  end

  def controlled_properties
    @controlled_properties ||= profile_properties.filter_map do |_name, config|
      service = authority_service_for(authority_source(config))
      next unless service.respond_to?(:label)

      indexing_keys = Array(config['indexing'])

      [indexing_keys, service]
    end
  end

  def profile_properties
    @profile_properties ||= Hyrax::FlexibleSchema.order('created_at asc').last&.profile&.dig('properties') || {}
  end

  def authority_source(config)
    return unless config.is_a?(Hash)

    sources = Array(config.dig('controlled_values', 'sources')).map { |source| source.to_s.strip }
    sources.find { |source| source.present? && source != 'null' }
  end

  def authority_service_for(source)
    return if source.blank?

    @authority_service ||= {}
    return @authority_service[source] if @authority_service.key?(source)

    service = controlled_vocabulary_service_for(source)
    service = service.new if service.is_a?(Class)
    @authority_service[source] = backed_by_authority?(service, source) ? service : nil
  end

  def backed_by_authority?(service, source)
    return false unless service.respond_to?(:authority)

    service.authority.present?
  rescue Qa::InvalidSubAuthority => e
    Rails.logger.warn "No authority backs the controlled vocabulary #{source}: #{e.message}"
    false
  end

  def authority_label(services, value)
    return value if identifier?(value)

    services.each do |service|
      label = service.label(value) { nil }
      return label if label.present?
    end

    value
  end

  def identifier?(value)
    URI.parse(value.to_s).absolute?
  rescue URI::InvalidURIError
    false
  end
end
