# frozen_string_literal: true

# Deletes anonymous Blacklight searches older than a cutoff from the current tenant.
# Searches saved by a user (user_id present) are never touched.
class OldSearchesPruner < BatchedPruner
  DEFAULT_OLDER_THAN_DAYS = 30

  private

  def scope
    Search.where(user_id: nil).where(created_at: ...cutoff)
  end

  def description
    'old anonymous searches'
  end
end
