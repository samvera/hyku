# frozen_string_literal: true

module Hyku
  ##
  # Subscribes listeners from `to_prepare` blocks, which run again on every code
  # reload in development.
  module ListenerSubscription
    ##
    # `Dry::Events` unsubscribes by object identity, and an earlier instance's
    # class may since have been unloaded, so earlier subscriptions are found by
    # class name.
    def self.replace(listener, publisher: Hyrax.publisher)
      class_name = listener.class.name
      publisher.__bus__.listeners.values.flatten(1)
               .filter_map { |callable, _filter| callable.receiver if callable.is_a?(Method) }
               .select { |receiver| receiver.class.name == class_name }
               .uniq
               .each { |subscribed| publisher.unsubscribe(subscribed) }
      publisher.subscribe(listener)
    end
  end
end
