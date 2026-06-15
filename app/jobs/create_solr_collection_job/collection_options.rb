# frozen_string_literal: true

# Transform settings from nested, snaked-cased options to flattened, camel-cased
# options for Solr collection creation.
class CreateSolrCollectionJob::CollectionOptions
  attr_reader :settings

  def initialize(settings = {})
    @settings = settings
  end

  ##
  # @example Camel-casing
  #   { replication_factor: 5 } # => { "replicationFactor" => 5 }
  # @example Blank-rejecting
  #   { emptyValue: '' } #=> { }
  # @example Nested value-flattening
  #   { collection: { config_name: 'x' } } # => { 'collection.configName' => 'x' }
  def to_h
    Hash[*settings.map { |k, v| transform_entry(k, v) }.flatten].reject { |_k, v| v.blank? }.symbolize_keys
  end

  private

  def transform_entry(k, v)
    case v
    when Hash
      v.map do |k1, v1|
        ["#{transform_key(k)}.#{transform_key(k1)}", v1]
      end
    else
      [transform_key(k), v]
    end
  end

  def transform_key(k)
    k.to_s.camelize(:lower)
  end
end
