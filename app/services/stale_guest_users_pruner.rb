# frozen_string_literal: true

# Deletes guest users not updated since a cutoff. Users are shared across tenants, so this runs once.
# Uses bulk delete_all: guest users carry no dependent bookmarks, searches, trophies or proxy-deposit records.
class StaleGuestUsersPruner < BatchedPruner
  DEFAULT_OLDER_THAN_DAYS = 7

  private

  def scope
    User.unscoped.where(guest: true).where(updated_at: ...cutoff)
  end

  def description
    'stale guest users'
  end
end
