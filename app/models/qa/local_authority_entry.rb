# frozen_string_literal: true

module Qa
  class LocalAuthorityEntry < ApplicationRecord
    belongs_to :local_authority
  end
end
