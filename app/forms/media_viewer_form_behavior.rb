# frozen_string_literal: true

# The static schema puts media_viewer on every work type at class load, with no opt-in
# of its own, so without this a deploy would offer a viewer picker that
# Hyku::MediaViewerBehavior ignores. Flexible mode withholds the field via the profile
# instead, leaving this nothing to remove.
module MediaViewerFormBehavior
  extend ActiveSupport::Concern

  def secondary_terms
    return super if Flipflop.per_work_media_viewer?

    super - [:media_viewer]
  end

  def primary_terms
    return super if Flipflop.per_work_media_viewer?

    super - [:media_viewer]
  end
end
