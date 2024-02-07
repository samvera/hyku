# frozen_string_literal: true

# OVERRIDE Hyrax 5.0 to add basic metadata and AF methods to collection

Hyrax::PcdmCollection.class_eval do
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::ArResource

  # This module provides the #public?, #private?, #registered? methods; consider contributing this
  # back to Hyrax; but that decision requires further discussion on architecture.
  # @see https://samvera.slack.com/archives/C0F9JQJDQ/p1705421588370699 Slack discussion thread.
  include Hyrax::Permissions::Readable
  prepend OrderAlready.for(:creator)
end
