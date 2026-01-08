# frozen_string_literal: true

# Fix for Rails 7.2 compatibility: ActiveFedora's railtie tries to modify frozen autoload paths
# This ensures autoload_paths are not frozen when ActiveFedora tries to modify them
# The path is already added in config/application.rb, but this provides a safety net
Rails.application.config.before_initialize do
  if defined?(ActiveFedora::Railtie)
    ActiveFedora::Railtie.class_eval do
      # Override the initializer that sets autoload paths to handle frozen arrays
      initializer 'active_fedora.autoload', before: :set_autoload_paths do |app|
        # Ensure autoload_paths is not frozen before ActiveFedora tries to modify them
        app.config.autoload_paths = app.config.autoload_paths.dup if app.config.autoload_paths.frozen?
      end
    end
  end
end
