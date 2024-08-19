# frozen_string_literal: true

module VideoEmbedFormBehavior
  extend ActiveSupport::Concern

  included do
    self.terms += %i[video_embed]
  end

  def secondary_terms
    super.sort!
  end
end
