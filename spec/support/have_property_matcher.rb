# frozen_string_literal: true
# Helper methods for the have_property matcher defined below.
# These helpers keep the matcher itself cleaner.
module HavePropertyHelpers
  def has_property?(model, property_name)
    model.send(:properties).key? property_name.to_s
  end

  def has_predicate?(model, property_name, compare_predicate)
    if has_property?(model, property_name)
      predicate = model.send(:properties)[property_name.to_s].predicate

      return !!(predicate =~ compare_predicate) if compare_predicate.is_a? Regexp
      return predicate == compare_predicate
    end
    false
  end

  def get_failure_message(model, property_name, predicate: nil)
    if !has_property?(model, property_name)
      "expected #{model} to have property: '#{property_name}'"
    elsif predicate && !has_predicate?(model, property_name, predicate)
      "expected #{model} property '#{property_name}' to have predicate: '#{predicate}'"
    end
  end

  def get_negated_failure_message(model, property_name, predicate: nil)
    if predicate && has_predicate?(model, property_name, predicate)
      "expected #{model} property '#{property_name}' to not have predicate: '#{predicate}'"
    elsif has_property?(model, property_name)
      "expected #{model} to not have property: '#{property_name}''"
    end
  end

  def object_is_not_af_model_error(obj)
    ArgumentError.new("the 'have_property' matcher only works for " \
                      "instances of ActiveFedora::Base, not #{obj.class}")
  end
end

# Custom RSpec matcher for ActiveFedora model instances.
# Usage:
#   expect(model).to have_property :title
#   expect(model).to have_property :title, predicate: ::RDF::Vocab::DC.title
#   expect(model).to have_property :title, predicate: "http://purl.org/dc/terms/title"
#   expect(model).to have_property :title, predicate: /purl\.org\/dc.*title/
RSpec::Matchers.define :have_property do |property_name|
  include HavePropertyHelpers
  match do |model|
    raise object_is_not_af_model_error(model) unless model.is_a? ActiveFedora::Base
    pass = has_property?(model, property_name)
    pass &= has_predicate?(model, property_name, @predicate) if @predicate
    pass
  end

  # Allows you to chain a .with_predicate() matcher.
  # Example: expect(model).to have_propety(:title).with_predicate(::RDF::Vocab::DC.title)
  chain(:with_predicate) { |predicate| @predicate = predicate }

  failure_message { |model| get_failure_message(model, property_name, predicate: @predicate) }
  failure_message_when_negated { |model| get_negated_failure_message(model, property_name, predicate: @predicate) }
end
