# frozen_string_literal: true

class ConvertPdfToJpgJob < ApplicationJob
  def perform(files, curation_concern, attributes)
    jpg_files = CreateJpgService.new(files, cached: false).create_jpgs
    return true if jpg_files.blank?
    AttachFilesToWorkJob.perform_now(curation_concern, jpg_files, attributes.to_h.symbolize_keys)
    DeleteJpgFilesJob.perform_later(files)
  end
end
