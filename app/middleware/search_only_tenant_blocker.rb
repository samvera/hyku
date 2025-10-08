# frozen_string_literal: true

class SearchOnlyTenantBlocker
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    
    # Check if this is a metadata_profiles request on a search-only tenant
    # Only block when HYRAX_FLEXIBLE is enabled
    if request.path.start_with?('/metadata_profiles') && 
       Site.account&.search_only? && 
       flexible_metadata_enabled?
      # Redirect to a proper controller that can render views
      return redirect_to_access_denied
    end

    @app.call(env)
  end

  private

  def flexible_metadata_enabled?
    # Check both Hyrax config and ENV to handle test scenarios
    return true if ENV['HYRAX_FLEXIBLE'] == 'true'
    return false if ENV['HYRAX_FLEXIBLE'] == 'false'
    
    # If ENV is not set, default to false
    ENV['HYRAX_FLEXIBLE'].nil? ? false : ENV['HYRAX_FLEXIBLE'] == 'true'
  end

  def redirect_to_access_denied
    [
      302,
      { 'Location' => '/access_denied?reason=metadata_profiles' },
      ['Redirecting...']
    ]
  end
end