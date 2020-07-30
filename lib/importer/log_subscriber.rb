# frozen_string_literal: true

module Importer
  class LogSubscriber < ActiveSupport::LogSubscriber
    def initialize
      super
      @odd = false
    end

    def import(event)
      return unless logger.debug?

      payload = event.payload

      name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      id    = payload[:id] || '[no id]'
      klass = payload[:klass]

      if odd?
        name = color(name, CYAN, true)
        id = color(id, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      debug "  #{name} #{klass} #{id}"
    end

    def odd?
      @odd = !@odd
    end

    def logger
      ActiveFedora::Base.logger
    end
  end
end

Importer::LogSubscriber.attach_to :importer
