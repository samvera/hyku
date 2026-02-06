# frozen_string_literal: true

## remove non-UTF-8 characters from a text string
module ScrubText
  def scrub_text(text)
    text.tr("\n", ' ')
        .squeeze(' ')
        .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end
end
