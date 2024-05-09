# frozen_string_literal: true

class PruneStaleGuestUsersJob < ApplicationJob
  non_tenant_job
  # TODO: disable this job for deploy
  # repeat 'every week at 8am' # midnight PST

  def perform
    RolesService.prune_stale_guest_users
  end
end
