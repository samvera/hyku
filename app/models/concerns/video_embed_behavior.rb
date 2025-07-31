# frozen_string_literal: true

module VideoEmbedBehavior
  extend ActiveSupport::Concern

  included do
    include Validation
    property :video_embed, predicate: ::RDF::URI("https://atla.com/terms/video_embed"), multiple: false do |index|
      index.as :stored_searchable
    end
  end

  module Validation
    extend ActiveSupport::Concern
    included do
      validates :video_embed,
                allow_blank: true,
                format: {
                  with: %r{(http://|https://)(www\.)?(player\.vimeo\.com|youtube\.com/embed)},
                  message: lambda { |_object, _data|
                             I18n.t('errors.messages.valid_embed_url',
                                                            default: 'must be a valid YouTube or Vimeo Embed URL.')
                           }
                },
                if: :responds_to_video_embed?
    end

    private

    def responds_to_video_embed?
      respond_to?(:video_embed)
    end
  end
end
