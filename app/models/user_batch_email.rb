# frozen_string_literal:true

class UserBatchEmail < ApplicationRecord
  self.table_name = 'user_batch_emails'
  belongs_to :user, class_name: '::User'
end
