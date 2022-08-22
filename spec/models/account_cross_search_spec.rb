# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountCrossSearch, type: :model do
  it do
    expect(subject).to belong_to(:full_account)
      .class_name('Account')

    expect(subject).to belong_to(:search_account)
      .class_name('Account')
  end
end
