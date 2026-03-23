# frozen_string_literal: true

# OVERRIDE: Hyrax v5.0.x: Work around Sipity being unable to find the Entity for
# a solr document when using lazy migration or Valkyrie-only (no Wings/Fedora)
# mode. We need the actual work (resolved via query_service) so that
# proxy_for_global_id matches what is stored in Sipity::Entity; using
# SolrDocument#to_model can yield the wrong model and break workflow lookups.
# Due to loading sequence issues the entire module is included in the override.
# See https://github.com/samvera/hyrax/issues/7028
# rubocop:disable Metrics/ModuleLength
module Sipity
  ##
  # Cast a given input (e.g. a +::User+ or {Hyrax::Group} to a {Sipity::Agent}).
  #
  # @param input [Object]
  #
  # @return [Sipity::Agent]
  def Agent(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Agent
               input
             end

    handle_conversion(input, result, :to_sipity_agent, &block)
  end
  module_function :Agent

  ##
  # Cast an object to an Entity
  #
  # @param input [Object]
  #
  # @return [Sipity::Entity]
  # rubocop:disable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def Entity(input, &block) # rubocop:disable Metrics/AbcSize
    Hyrax.logger.debug("Trying to make an Entity for #{input.inspect}")

    result = case input
             when Sipity::Entity
               input
             when URI::GID, GlobalID
               Hyrax.logger.debug("Entity() got a GID, searching by proxy")
               gid_string = input.to_s
               Hyrax.logger.debug("  Searching for GID: #{gid_string}")
               entity_find_by_gid(input, gid_string)
             when SolrDocument
               if Hyrax.config.disable_wings
                 # In no-Wings mode, resolve via query_service instead of
                 # SolrDocument#to_model, which can trigger ActiveFedora/Fedora lookups.
                 item = Hyrax.query_service.find_by(id: input.id)
                 # rubocop:disable Lint/RedundantStringCoercion
                 Hyrax.logger.debug("Entity() got a SolrDocument in valkyrie/no-wings mode, retrying on item #{item.id.to_s}")
                 # rubocop:enable Lint/RedundantStringCoercion
                 Entity(item)
               else
                 model = input.to_model
                 Hyrax.logger.debug("Entity() got a SolrDocument, retrying on #{model}")
                 Entity(model)
               end
             when Draper::Decorator
               Hyrax.logger.debug("Entity() got a Decorator, retrying on #{input.model}")
               Entity(input.model)
             when Sipity::Comment
               Hyrax.logger.debug("Entity() got a Comment, retrying on #{input.entity}")
               Entity(input.entity)
             when Valkyrie::Resource
               Hyrax.logger.debug("Entity() got a Resource, retrying on #{Hyrax::GlobalID(input)}")
               Entity(Hyrax::GlobalID(input))
             else
               Hyrax.logger.debug("Entity() got something else (#{input.class}), testing #to_global_id")
               if input.respond_to?(:to_global_id)
                 the_gid_obj = input.to_global_id
                 Hyrax.logger.debug("  Generated GID object: #{the_gid_obj.inspect}")
                 Hyrax.logger.debug("  Calling Entity recursively with GID object.")
                 Entity(the_gid_obj)
               end
             end

    Hyrax.logger.debug("Entity(): attempting conversion on input: #{input.inspect} with result: #{result.inspect}")
    handle_conversion(input, result, :to_sipity_entity, &block)
  rescue URI::GID::MissingModelIdError
    Entity(nil)
  end # rubocop:enable Metrics/AbcSize
  module_function :Entity
  # rubocop:enable Naming/MethodName, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  ##
  # Cast an object to an Role
  def Role(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Role
               input
             when String, Symbol
               Sipity::Role.find_or_create_by(name: input)
             end

    handle_conversion(input, result, :to_sipity_role, &block)
  end
  module_function :Role

  ##
  # Cast an object to a Workflow id
  # rubocop:disable Metrics/MethodLength
  def WorkflowId(input, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::Workflow
               input.id
             when Integer
               input
             when String
               input.to_i
             else
               if input.respond_to?(workflow_id)
                 input.workflow_id
               else
                 WorkflowId(Entity(input))
               end
             end
    handle_conversion(input, result, :to_workflow_id, &block)
  end
  module_function :WorkflowId
  # rubocop:enable Metrics/MethodLength

  ##
  # Cast an object to a WorkflowAction in a given workflow
  def WorkflowAction(input, workflow, &block) # rubocop:disable Naming/MethodName
    workflow_id = WorkflowId(workflow)

    result = case input
             when WorkflowAction
               input if input.workflow_id == workflow_id
             when String, Symbol
               WorkflowAction.find_by(workflow_id: workflow_id, name: input.to_s)
             end

    handle_conversion(input, result, :to_sipity_action, &block)
  end
  module_function :WorkflowAction

  ##
  # Cast an object to a WorkflowState in a given workflow
  def WorkflowState(input, workflow, &block) # rubocop:disable Naming/MethodName
    result = case input
             when Sipity::WorkflowState
               input
             when Symbol, String
               WorkflowState.find_by(workflow_id: workflow.id, name: input)
             end

    handle_conversion(input, result, :to_sipity_workflow_state, &block)
  end
  module_function :WorkflowState

  ##
  # A parent error class for all workflow errors caused by bad state
  class StateError < RuntimeError; end

  class ConversionError < RuntimeError
    def initialize(value)
      super("Unable to convert #{value.inspect}")
    end
  end

  ##
  # Find Sipity::Entity by proxy_for_global_id, with fallback for ValkyrieGlobalIdProxy GIDs
  # when the entity was stored with a concrete or legacy model name.
  def entity_find_by_gid(gid_input, gid_string)
    result = Entity.find_by(proxy_for_global_id: gid_string)
    return result unless result.nil? && gid_string.include?("ValkyrieGlobalIdProxy")

    entity_find_by_valkyrie_proxy_gid(gid_input, gid_string)
  end
  module_function :entity_find_by_gid

  def entity_find_by_valkyrie_proxy_gid(gid_input, gid_string)
    resolved = GlobalID::Locator.locate(gid_input)
    return nil unless resolved.is_a?(Valkyrie::Resource)

    app = gid_input.respond_to?(:app) ? gid_input.app : URI.parse(gid_string).host
    result = Entity.find_by(proxy_for_global_id: "gid://#{app}/#{resolved.class.name}/#{resolved.id}")
    return result if result.present?
    return Entity.find_by(proxy_for_global_id: "gid://#{app}/#{resolved.internal_resource}/#{resolved.id}") if resolved.respond_to?(:internal_resource)

    nil
  rescue StandardError => e
    Hyrax.logger.debug("  Entity() ValkyrieGlobalIdProxy fallback failed: #{e.message}")
    nil
  end
  module_function :entity_find_by_valkyrie_proxy_gid

  ##
  # Provides compatibility with the old `PowerConverter` conventions
  def handle_conversion(input, result, method_name)
    result ||= input.try(method_name)
    return result unless result.nil?
    return yield if block_given?

    raise ConversionError.new(input) # rubocop:disable Style/RaiseArgs
  end
  module_function :handle_conversion
end
# rubocop:enable Metrics/ModuleLength
