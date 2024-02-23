# frozen_string_literal: true

class DeleteJpgFilesJob < ApplicationJob
  def perform(files)
    files.each do |file|
      basename = file.file.file.basename
      directory = Rails.root.join("tmp", "jpgs", basename[0...-7])
      FileUtils.rm_rf(directory) if directory.present?
    end
  end
end
