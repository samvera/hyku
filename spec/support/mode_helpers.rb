# frozen_string_literal: true

module ModeHelpers
  def no_wings_mode?
    Hyrax.config.disable_wings
  end

  def with_disable_wings(value)
    allow(Hyrax.config).to receive(:disable_wings).and_return(value)
    yield if block_given?
  end

  def with_valkyrie_transition(value)
    allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(value)
    yield if block_given?
  end
end

RSpec.configure do |config|
  config.include ModeHelpers
end
