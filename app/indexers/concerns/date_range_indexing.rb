# frozen_string_literal: true

# Index a numeric year for every work so the catalog can offer a date range
# facet. Date properties are auto-detected from the M3 profile (any property
# with `syntax: edtf`) when flexible metadata is on, falling back to
# `date_created` otherwise.
module DateRangeIndexing
  SOLR_FIELD = 'date_range_isim'

  # Both paths must be defined: ActiveFedora calls generate_solr_document,
  # Valkyrie calls to_solr.
  [:generate_solr_document, :to_solr].each do |method_name|
    define_method method_name do |*args, **kwargs, &block|
      super(*args, **kwargs, &block).tap do |solr_doc|
        object = respond_to?(:resource) ? resource : (self.object || @object)
        years = Hyku::DateRangeYears.call(date_values_for_range(object))

        solr_doc[SOLR_FIELD] = years if years.any?
      end
    end
  end

  private

  def date_values_for_range(object)
    date_properties.map { |property| object.try(property) }
  end

  def date_properties
    return self.class.edtf_date_properties if self.class.respond_to?(:edtf_date_properties)

    if Hyrax.config.flexible? && defined?(Hyrax::Schema)
      self.class.instance_variable_get(:@edtf_date_properties) ||
        self.class.instance_variable_set(:@edtf_date_properties, detect_edtf_properties)
    else
      %i[date_created]
    end
  end

  def detect_edtf_properties
    config_path = Hyrax::Schema.m3_schema_loader.config_paths.first&.to_s
    return %i[date_created] if config_path.blank?

    profile = YAML.safe_load_file(config_path)
    props = profile.fetch('properties', {})
                   .select { |_name, prop| prop['syntax'].to_s.casecmp?('edtf') }
                   .keys
                   .map(&:to_sym)

    props.empty? ? %i[date_created] : props
  rescue StandardError
    %i[date_created]
  end
end
