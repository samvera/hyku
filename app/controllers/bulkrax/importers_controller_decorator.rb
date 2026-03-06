# frozen_string_literal: true

# OVERRIDE Bulkrax to gate guided import actions behind the :include_guided_import feature flag.
module Bulkrax
  module ImportersControllerDecorator
    def guided_import_new
      require_guided_import_feature { super }
    end

    def guided_import_create
      require_guided_import_feature { super }
    end

    def guided_import_validate
      require_guided_import_feature { super }
    end

    def guided_import_demo_scenarios
      require_guided_import_feature { super }
    end

    private

    def require_guided_import_feature
      if Flipflop.include_guided_import?
        yield
      else
        redirect_to bulkrax.importers_path, alert: t('bulkrax.importer.guided_import.flash.feature_disabled', default: 'Guided import is not enabled.')
      end
    end
  end
end

Bulkrax::ImportersController.prepend(Bulkrax::ImportersControllerDecorator)
