class Site < ActiveRecord::Base
  resourcify

  validates :application_name, presence: true, allow_nil: true

  belongs_to :account
  accepts_nested_attributes_for :account, update_only: true

  class << self
    delegate :account, :application_name, :institution_name, :institution_name_full, :reload, :update, to: :instance

    def instance
      first || create
    end
  end
end
