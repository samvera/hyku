class Site < ActiveRecord::Base
  resourcify

  validates :application_name, presence: true, allow_nil: true

  belongs_to :account
  has_many :content_blocks
  accepts_nested_attributes_for :account, update_only: true

  delegate :announcement_text, :marketing_text, :featured_researcher,
           :announcement_text=, :marketing_text=, :featured_researcher=,
           to: :content_blocks

  def content_by_name(name)
    content_blocks.find_by_name(name) || content_blocks.create(name: name)
  end

  def set_content_by_name(name, value)
    content_by_name(name).update(value: value)
  end

  def update_content(params)
    params.each do |n, v|
      set_content_by_name(n, v)
    end
  end

  class << self
    delegate :account, :application_name, :institution_name,
             :institution_name_full, :reload, :update, :announcement_text,
             :marketing_text, :featured_researcher, :announcement_text=,
             :marketing_text=, :featured_researcher=, :about_page, :about_page=,
             :content_by_name, :set_content_by_name,
             to: :instance

    def instance
      first_or_create
    end
  end
end
