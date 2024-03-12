# frozen_string_literal: true

class PruneStaleGuestUsersJob < ApplicationJob
  non_tenant_job
  repeat 'every week at 8am' # midnight PST

  def perform
    RolesService.prune_stale_guest_users
  end
end
