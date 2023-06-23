# frozen_string_literal: true

class FileSetIndexJob < Hyrax::ApplicationJob
  def perform(file_set)
    file_set&.update_index
  end
end