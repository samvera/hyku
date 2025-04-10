# frozen_string_literal: true

# CreateLargeDerivativesJob is intended to be used for resource-intensive derivative
# generation (e.g. video processing). It is functionally similar to CreateDerivativesJob,
# except that it queues jobs in the :auxiliary queue.
#
# The worker responsible for processing jobs in the :auxiliary queue should be
# configured to have more resources dedicated to it, especially CPU. Otherwise, the
# `ffmpeg` commands that this job class eventually triggers could be throttled.
#
# @see CreateDerivativesJobDecorator
# @see Hydra::Derivatives::Processors::Ffmpeg
# @see https://github.com/notch8/palni-palci/issues/852
class CreateLargeDerivativesJob < CreateDerivativesJob
  queue_as :auxiliary
end
