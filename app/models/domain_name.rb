# frozen_string_literal: true

class DomainName < ApplicationRecord
  belongs_to :account
  validates :cname, presence: true, uniqueness: true, exclusion: { in: [Account.default_cname('')] }
  before_save :canonicalize_cname

  def canonicalize_cname
    self.cname &&= Account.canonical_cname(cname)
  end
end
