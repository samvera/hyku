# frozen_string_literal: true

# Shared concern for appearance-related controllers to handle tab navigation
module AppearanceTabNavigation
  extend ActiveSupport::Concern

  private

  def extract_tab_from_referer
    return nil unless request.referer
    # Extract tab from referer URL (e.g., /admin/appearance#themes)
    match = request.referer.match(/#(\w+)$/)
    match ? match[1] : nil
  end
end
