# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0
# @see CreateLargeDerivativesJob
module CreateDerivativesJobDecorator
  # OVERRIDE: Divert audio and video derivative
  # creation to CreateLargeDerivativesJob.
  def perform(file_set, file_id, filepath = nil)
    return super if is_a?(CreateLargeDerivativesJob)
    return super unless file_set.video? || file_set.audio?

    CreateLargeDerivativesJob.perform_later(*arguments)
    true
  end
end

CreateDerivativesJob.prepend(CreateDerivativesJobDecorator)
