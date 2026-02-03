# frozen_string_literal: true

module Hyku
  module FileRenameable
    def filename
      return if original_filename.blank?

      account_id = model.account&.tenant
      time_stamp = Time.now.utc.to_i
      extension = File.extname(original_filename)

      [account_id, time_stamp].join('_') + extension
    end
  end
end
