# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 This file required for various specs (no changes)
# Defines a new sequence
FactoryBot.define do
  sequence :object_id do |n|
    "object_id_#{n}"
  end
end
