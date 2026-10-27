# frozen_string_literal: true

module Hyku
  ##
  # Keeps per-tenant values that Account#switch! writes into shared gem config on the current
  # thread, so a concurrent request for another tenant can't swap them mid-request.
  #
  # Until a thread switches tenants (boot, initializers, a plain console) the wrapped writers and
  # readers behave exactly as before. After .reset!, which every tenant switch calls first, writes
  # stay on that thread and readers fall back to the boot value for anything the tenant didn't set.
  module PerThread
    STATE_KEY = :hyku_per_thread

    class << self
      # @param target [Module, Object] what to prepend onto: a class for instance attributes, or a
      #   singleton class for class-level attributes
      # @param name [Symbol] the attribute; its writer is "#{name}="
      # @param readers [Array<Symbol>] reader methods returning the attribute
      # @param owner [Object] what the value is stored against. Defaults to the class a singleton
      #   class belongs to, so subclasses read the value written on it, as they would through
      #   inheritance, while a subclass writing its own value keeps it; otherwise each instance has
      #   its own value.
      # @param copy [Boolean] give each thread its own copy of the boot value on first read, for
      #   values callers mutate in place (e.g. a Hash)
      # @param falsy_falls_back [Boolean] when the stored value is falsy, read the reader's default
      #   from a fresh instance instead, for readers that memoize an ENV default with `||=`. Only
      #   for instance attributes (e.g. Hyrax::Configuration).
      # rubocop:disable Metrics/ParameterLists
      def attribute(target, name, readers: [name], owner: nil, copy: false, falsy_falls_back: false)
        # to_prepare runs again on every development reload, but the gem classes wrapped here don't reload
        registration = [name, readers]
        return if target.ancestors.any? { |mod| mod.instance_variable_get(:@hyku_per_thread) == registration }
        subclass_writes_own = owner.nil? && target.singleton_class?
        owner ||= target.attached_object if target.singleton_class?
        accessors = accessor_module(name, readers, owner, copy, falsy_falls_back, subclass_writes_own)
        accessors.instance_variable_set(:@hyku_per_thread, registration)
        target.prepend(accessors)
      end
      # rubocop:enable Metrics/ParameterLists

      def reset!
        state[:values] = {}
        state[:active] = true
      end

      def active?
        state[:active] == true
      end

      def key?(owner, name)
        values.key?([owner.object_id, name])
      end

      def read(owner, name)
        values[[owner.object_id, name]]
      end

      def write(owner, name, value)
        values[[owner.object_id, name]] = value
      end

      def keep_write?(receiver, owner, subclass_writes_own)
        active? && !(subclass_writes_own && !receiver.equal?(owner))
      end

      private

      def state
        ActiveSupport::IsolatedExecutionState[STATE_KEY] ||= {}
      end

      def values
        state[:values] ||= {}
      end

      # rubocop:disable Metrics/MethodLength
      def accessor_module(name, readers, owner, copy, falsy_falls_back, subclass_writes_own) # rubocop:disable Metrics/ParameterLists
        Module.new do
          define_method(:"#{name}=") do |value|
            return super(value) unless Hyku::PerThread.keep_write?(self, owner, subclass_writes_own)
            Hyku::PerThread.write(owner || self, name, value)
          end

          readers.each do |reader|
            define_method(reader) do |*args, &block|
              key = owner || self
              return super(*args, &block) unless Hyku::PerThread.active?
              if Hyku::PerThread.key?(key, name)
                value = Hyku::PerThread.read(key, name)
                return value if value || !falsy_falls_back
                return self.class.allocate.public_send(reader, *args, &block)
              end
              return super(*args, &block) unless copy

              Hyku::PerThread.write(key, name, super(*args, &block).deep_dup)
            end
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
