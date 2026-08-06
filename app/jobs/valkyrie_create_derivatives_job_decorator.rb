# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0
# @see ValkyrieCreateLargeDerivativesJob
module ValkyrieCreateDerivativesJobDecorator
  # OVERRIDE: Divert audio and video derivative
  # creation to ValkyrieCreateLargeDerivativesJob.
  def perform(file_set_id, file_id, *args)
    return super if is_a?(ValkyrieCreateLargeDerivativesJob)

    file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file_id)
    return super unless file_metadata.video? || file_metadata.audio?

    ValkyrieCreateLargeDerivativesJob.perform_later(file_set_id, file_id, *args)
    true
  end
end

ValkyrieCreateDerivativesJob.prepend(ValkyrieCreateDerivativesJobDecorator)
