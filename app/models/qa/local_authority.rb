# frozen_string_literal: true

module Qa
  class LocalAuthority < ApplicationRecord
    has_many :local_authority_entries, dependent: :destroy
  end
end
