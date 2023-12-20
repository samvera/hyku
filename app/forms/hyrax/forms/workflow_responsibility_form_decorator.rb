# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 Expand to allow adding groups to workflow roles

module Hyrax
  module Forms
    module WorkflowResponsibilityFormDecorator
      module ClassMethods
        # Determine which form it is, user or group
        def new(params = {})
          if params[:user_id].present?
            super
          else
            Forms::WorkflowResponsibilityGroupForm.new(params)
          end
        end
      end
    end
  end
end

Hyrax::Forms::WorkflowResponsibilityForm.singleton_class
                                        .send(:prepend, Hyrax::Forms::WorkflowResponsibilityFormDecorator::ClassMethods)
