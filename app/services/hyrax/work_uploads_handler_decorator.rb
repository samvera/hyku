# frozen_string_literal: true

# OVERRIDE add the is_derived field to the file set
module Hyrax
  module WorkUploadsHandlerDecorator
    ##
    # OVERRIDE
    #
    # @see https://github.com/notch8/palni-palci/blob/29f7e331a76751cf2c237e7fb2121bea38a9056b/app/jobs/attach_files_to_work_job.rb#L22
    def file_set_args(file)
      hash = super
      # NOTE: The respond to is me (Jeremy) being cautios.  I checked the
      #       various repositories to see where `derived?` might be implemented
      #       and found nothing.
      hash = hash.merge(is_derived: file.derived?) if file.respond_to?(:derived?)
      hash
    end
  end
end

Hyrax::WorkUploadsHandler.prepend(Hyrax::WorkUploadsHandlerDecorator)
