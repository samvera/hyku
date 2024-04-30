# frozen_string_literal: true
# OVERRIDE FILE from Hyrax v5.0.0

##
# Ensure the current user matches the requested URL.
Hyrax::Dashboard::ProfilesController.before_action :users_match!, only: %i[show edit update]
