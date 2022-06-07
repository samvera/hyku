# frozen_string_literal: true

module ApplicationHelper
  include ::HyraxHelper
  include Hyrax::OverrideHelperBehavior
  include GroupNavigationHelper

  include SharedSearchHelper

  def display_pdfs_in_uv?
    Flipflop.show_pdfs_in_uv?
  end
end
