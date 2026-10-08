# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe GenericWorkResource do
  subject(:work) { described_class.new }

  # TODO: Register a test adapter
  it_behaves_like 'a Hyrax::Work'

  describe '#creator' do
    it 'is ordered by user input' do
      work.creator = ["Jeremy", "Shana"]

      # NOTE: This demonstrates how OrderAlready interacts with a ValkyrieResource.  It is possible
      # that we have an incorrect interaction, and this test is useless.  We'll know more as we work
      # through use cases.
      expect(work.attributes[:creator]).to eq(["0~Jeremy", "1~Shana"])

      expect(work.creator).to eq(["Jeremy", "Shana"])
    end
  end

  describe 'class configuration' do
    subject { described_class }

    its(:migrating_from) { is_expected.to eq(GenericWork) }
    its(:migrating_to) { is_expected.to eq(GenericWorkResource) }

    describe '.model_name' do
      subject { described_class.model_name }

      its(:klass) { is_expected.to eq GenericWorkResource }
      its(:name) { is_expected.to eq "GenericWorkResource" }

      its(:singular) { is_expected.to eq "generic_work" }
      its(:plural) { is_expected.to eq "generic_works" }
      its(:element) { is_expected.to eq "generic_work" }
      its(:human) { is_expected.to eq "Generic Work" }
      its(:collection) { is_expected.to eq "generic_works" }
      its(:param_key) { is_expected.to eq "generic_work" }
      its(:i18n_key) { is_expected.to eq :generic_work }
      its(:route_key) { is_expected.to eq "hyrax_generic_works" }
      its(:singular_route_key) { is_expected.to eq "hyrax_generic_work" }
    end

    # Reproduces the intermittent "undefined method
    # `new_hyrax_parent_generic_work_resource_path'" bug. The race is:
    # `Hyrax::Naming.model_name` memoizes `@_model_name` the first time it is
    # called, using whatever `_hyrax_default_name_class` is at that moment.
    # The `Hyrax::ValkyrieLazyMigration.migrating` wiring — which installs
    # `ValkyrieLazyMigration::ResourceName` as the default name class and is
    # what makes `.singular == "generic_work"` — runs in `after_initialize`.
    # If anything (decorator, helper, presenter, autoloaded form) calls
    # `GenericWorkResource.model_name` before `after_initialize` finishes, the
    # cache is poisoned with a `Hyrax::ResourceName` that does not override
    # `@singular`, and `.singular` returns `"generic_work_resource"` for the
    # life of the process.
    describe 'memoization race (regression guard for intermittent routing error)' do
      around do |example|
        klass = described_class
        had_cache = klass.instance_variable_defined?(:@_model_name)
        cached = klass.instance_variable_get(:@_model_name) if had_cache
        original_default = klass.singleton_class.instance_method(:_hyrax_default_name_class)

        example.run
      ensure
        if had_cache
          klass.instance_variable_set(:@_model_name, cached)
        elsif klass.instance_variable_defined?(:@_model_name)
          klass.remove_instance_variable(:@_model_name)
        end
        klass.singleton_class.define_method(:_hyrax_default_name_class, original_default)
      end

      # Simulate "B before A": some early code touches model_name before the
      # ValkyrieLazyMigration wiring has had a chance to install the right
      # default name class.
      def force_bad_ordering!
        described_class.remove_instance_variable(:@_model_name) if described_class.instance_variable_defined?(:@_model_name)
        described_class.singleton_class.define_method(:_hyrax_default_name_class) { Hyrax::ResourceName }
        described_class.model_name # poisons @_model_name
      end

      it 'demonstrates the bug: poisoned cache yields the resource-suffixed singular' do
        force_bad_ordering!
        # Now simulate the after_initialize hook installing the correct name
        # class. Without an eviction, the already-cached @_model_name ignores it.
        described_class.singleton_class.define_method(:_hyrax_default_name_class) do
          Hyrax::ValkyrieLazyMigration::ResourceName
        end

        expect(described_class.model_name.singular).to eq('generic_work_resource')
      end

      it 'demonstrates the bug: polymorphic_path raises for the parent route' do
        force_bad_ordering!
        described_class.singleton_class.define_method(:_hyrax_default_name_class) do
          Hyrax::ValkyrieLazyMigration::ResourceName
        end

        expect do
          Rails.application.routes.url_helpers.polymorphic_path(
            [:new, :hyrax, :parent, described_class.model_name.singular.to_sym],
            parent_id: 'abc'
          )
        end.to raise_error(NoMethodError, /new_hyrax_parent_generic_work_resource_path/)
      end

      # This test asserts the CORRECT behavior: after the bad ordering occurs,
      # the class should still resolve .singular to "generic_work". It fails
      # today — which is exactly the production bug: nothing undoes the
      # poisoned cache once after_initialize has finished running. A durable
      # fix (e.g. moving `migrating(...)` into the class body, or installing a
      # permanent singleton `model_name` method) makes this pass.
      it 'the bad ordering must not leak into .singular (fails until durable fix lands)' do
        force_bad_ordering!
        # Re-install the correct default name class, as after_initialize does.
        described_class.singleton_class.define_method(:_hyrax_default_name_class) do
          Hyrax::ValkyrieLazyMigration::ResourceName
        end

        expect(described_class.model_name.singular).to eq('generic_work')
      end

      it 'polymorphic_path must resolve the legacy parent route (fails until durable fix lands)' do
        force_bad_ordering!
        described_class.singleton_class.define_method(:_hyrax_default_name_class) do
          Hyrax::ValkyrieLazyMigration::ResourceName
        end

        expect do
          Rails.application.routes.url_helpers.polymorphic_path(
            [:new, :hyrax, :parent, described_class.model_name.singular.to_sym],
            parent_id: 'abc'
          )
        end.not_to raise_error
      end
    end
  end
end
