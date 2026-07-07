# frozen_string_literal: true

module Hyrax
  module DepositWizard
    # Wizard context shared by the controller and its views: the active config,
    # per-request state, the work-type list, the stepper rail, and the work form.
    module Context
      extend ActiveSupport::Concern

      included do
        helper_method :wizard_config, :wizard_state, :available_work_types,
                      :item_stepper_steps, :work_form
      end

      # The seam downstream apps replace to add container types, suggestions, etc.
      def wizard_config
        Hyku::DepositWizard.config
      end

      def wizard_state
        @wizard_state ||= Hyku::DepositWizard::State.new(session[:deposit_wizard] ||= {})
      end

      # The work types the current user may create, exactly as the stock deposit
      # chooser lists them (tenant- and profile-filtered).
      def available_work_types
        Hyrax::QuickClassificationQuery.new(current_user).authorized_models
      end

      # Stepper rail for the single-item flow. The full dynamic step sets
      # (portfolio / item with-or-without files / batch) arrive with those steps;
      # this increment covers the item type -> upload -> detail -> review shape.
      def item_stepper_steps
        %i[type upload detail review].each_with_index.map do |key, i|
          { n: i + 1, label: t("hyku.deposit_wizard.stepper.item.#{key}") }
        end
      end

      def work_form
        @form
      end

      # Build the ResourceForm for the chosen work type, re-validating any values
      # entered on a prior visit so the fields render prepopulated.
      def build_work_form
        @form = Hyrax::FormFactory.new.build(work_resource_class.new, current_ability, self)
        @form.validate(wizard_state.attributes) if wizard_state.attributes.present?
      end

      # The chooser lists ActiveFedora model names, but the form needs the
      # Valkyrie resource class. Resolve by shared param_key against the
      # registered Valkyrie work classes (no Wings), falling back to the chosen
      # class when no Valkyrie class is registered.
      def work_resource_class
        chosen = wizard_state.work_type.constantize
        return chosen if chosen < Hyrax::Resource

        Hyrax::ModelRegistry.work_classes.detect do |klass|
          klass < Hyrax::Resource && klass.model_name.param_key == chosen.model_name.param_key
        end || chosen
      end

      def work_params
        params.fetch(wizard_state.work_type.constantize.model_name.param_key, {})
      end

      def needs_work_type?(step)
        self.class::STEPS_REQUIRING_WORK_TYPE.include?(step) && wizard_state.work_type.blank?
      end
    end
  end
end
