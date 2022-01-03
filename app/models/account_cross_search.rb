# frozen_string_literal: true

class AccountCrossSearch < ApplicationRecord
  belongs_to :search_account, class_name: "Account", inverse_of: :full_account_cross_searches
  belongs_to :full_account, class_name: "Account", inverse_of: :search_account_cross_searches

  accepts_nested_attributes_for :search_account
  accepts_nested_attributes_for :full_account
end
