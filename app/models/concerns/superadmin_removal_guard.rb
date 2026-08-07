# frozen_string_literal: true

# Refusal plumbing for the public demo tenant superadmin floor, shared by the
# two models that need it.
#
# Role changes apply on assignment rather than on save, so an assignment that
# would strip the last superadmin skips the removal, records that it did, and
# fails the save here. Site makes that decision; Account mirrors it, since the
# proprietor form edits an Account and would otherwise report success.
module SuperadminRemovalGuard
  extend ActiveSupport::Concern

  included do
    validate :superadmin_removal_permitted
  end

  # True when the last assignment declined to remove a superadmin because it
  # would have left a public demo tenant with none.
  def superadmin_removal_blocked?
    @superadmin_removal_blocked.present?
  end

  private

  # Records the outcome of the assignment just attempted, and so must be written
  # on the permitted path too: a flag that only ever latches on would fail a
  # later, valid save of the same record.
  attr_writer :superadmin_removal_blocked

  def superadmin_removal_permitted
    return unless superadmin_removal_blocked?

    errors.add(:superadmin_emails, :cannot_remove_last_superadmin)
  end
end
