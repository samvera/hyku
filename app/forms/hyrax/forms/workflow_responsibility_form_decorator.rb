# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Expand to allow adding groups to workflow roles

module Hyrax
  module Forms
    module WorkflowResponsibilityFormDecorator
      ##
      # @note We introduced this little crease in the code to allow for conditional switching; and
      #       thus avoid copying a very large controller
      #       (e.g. Hyrax::Admin::WorkflowRolesController)
      # @see Hyrax::Forms::WorkflowResponsibilityGroupForm
      module ClassMethods
        ##
        # Determine which form it is, user or group.  By default, it will be a user
        # (e.g. {Hyrax::Forms::WorkflowResponsibilityForm}); however when you provide a :group_id it
        # will be a group form (e.g. {Hyrax::Forms::WorkflowResponsibilityGroupForm}.
        def new(params = {})
          if params[:group_id].present?
            Forms::WorkflowResponsibilityGroupForm.new(params)
          else
            super
          end
        end
      end
    end
  end
end

Hyrax::Forms::WorkflowResponsibilityForm.singleton_class
                                        .send(:prepend, Hyrax::Forms::WorkflowResponsibilityFormDecorator::ClassMethods)
