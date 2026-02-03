# frozen_string_literal: true

# OVERRIDE Hyrax::AvatarUploader to rename uploaded avatar files

module Hyku
  class AvatarUploader < Hyrax::AvatarUploader
    include Hyku::FileRenameable
  end
end
