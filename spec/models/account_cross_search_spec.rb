# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountCrossSearch, type: :model do
  it do
    is_expected.to belong_to(:full_account)
      .class_name('Account')

    is_expected.to belong_to(:search_account)
      .class_name('Account')
  end
end
