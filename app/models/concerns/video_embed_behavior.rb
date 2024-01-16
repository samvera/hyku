# frozen_string_literal: true

module VideoEmbedBehavior
  extend ActiveSupport::Concern

  included do
    validates :video_embed,
              format: {
                with: %r{(http://|https://)(www\.)?(player\.vimeo\.com|youtube\.com/embed)},
                message: lambda do |_object, _data|
                  I18n.t('errors.messages.valid_embed_url', default: 'must be a valid YouTube or Vimeo Embed URL.')
                end
              },
              if: :video_embed?

    property :video_embed, predicate: ::RDF::URI("https://atla.com/terms/video_embed"), multiple: false do |index|
      index.as :stored_searchable
    end
  end

  def video_embed?
    video_embed.present?
  end
end
