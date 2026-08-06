# frozen_string_literal: true

# The Valkyrie counterpart to CreateLargeDerivativesJob. Valkyrie file sets get
# their derivatives via ValkyrieCreateDerivativesJob (enqueued by
# Hyrax::Listeners::FileListener), which inherits the :default queue. AV
# derivatives shell ffmpeg and belong on the resource-heavy :auxiliary queue.
#
# @see ValkyrieCreateDerivativesJobDecorator
# @see CreateLargeDerivativesJob
class ValkyrieCreateLargeDerivativesJob < ValkyrieCreateDerivativesJob
  queue_as :auxiliary
end
