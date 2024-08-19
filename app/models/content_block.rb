# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc to add home_text to registry and getter/setter methods - Adding themes
# NOTE: This class inherits from ApplicationRecord while Hyrax's version inherits from ActiveRecord::Base
#       so we cannot use the decorator pattern to override the methods.
# rubocop:disable Metrics/ClassLength
class ContentBlock < ApplicationRecord
  # The keys in this registry are "public" names for collaborator
  # objects, and the values are reserved names of ContentBlock
  # instances, which Hyrax uses as identifiers. Values also correspond
  # to names of messages that can be sent to the ContentBlock class to
  # return defined ContentBlock instances.
  NAME_REGISTRY = {
    marketing: :marketing_text,
    researcher: :featured_researcher,
    announcement: :announcement_text,
    about: :about_page,
    help: :help_page,
    terms: :terms_page,
    agreement: :agreement_page,
    home_text: :home_text,
    homepage_about_section_heading: :homepage_about_section_heading,
    homepage_about_section_content: :homepage_about_section_content
  }.freeze

  # NOTE: method defined outside the metaclass wrapper below because
  # `for` is a reserved word in Ruby.
  def self.for(key)
    key = key.respond_to?(:to_sym) ? key.to_sym : key
    raise ArgumentError, "#{key} is not a ContentBlock name" unless registered?(key)
    ContentBlock.public_send(NAME_REGISTRY[key])
  end

  class << self
    # @api public
    #
    # @param name [#to_s] the named content block
    # @param fallback_value [Object] if we don't have a named content block use this value.
    #
    # @return [Object] either the named block's value or the fallback_value.
    def block_for(name:, fallback_value: false)
      block = ContentBlock.find_by(name:)
      block&.value.presence || fallback_value
    end

    # @api public
    #
    # @param name [#to_s] the named content block
    # @param value [Object] the value to update the given content block
    def update_block(name:, value:)
      find_or_create_by(name: name.to_s).update!(value:)
    end

    def registered?(key)
      NAME_REGISTRY.include?(key)
    end

    def marketing_text
      find_or_create_by(name: 'marketing_text')
    end

    def marketing_text=(value)
      marketing_text.update(value:)
    end

    def announcement_text
      find_or_create_by(name: 'announcement_text')
    end

    def announcement_text=(value)
      announcement_text.update(value:)
    end

    def featured_researcher
      find_or_create_by(name: 'featured_researcher')
    end

    def featured_researcher=(value)
      featured_researcher.update(value:)
    end

    # OVERRIDE Hyrax v3.4.0 to add home_text getter/setter methods - Adding themes
    def home_text
      find_or_create_by(name: 'home_text')
    end

    def home_text=(value)
      home_text.update(value:)
    end

    def homepage_about_section_heading
      find_or_create_by(name: 'homepage_about_section_heading')
    end

    def homepage_about_section_heading=(value)
      homepage_about_section_heading.update(value:)
    end

    def homepage_about_section_content
      find_or_create_by(name: 'homepage_about_section_content')
    end

    def homepage_about_section_content=(value)
      homepage_about_section_content.update(value:)
    end

    def about_page
      find_or_create_by(name: 'about_page')
    end

    def about_page=(value)
      about_page.update(value:)
    end

    def agreement_page
      find_by(name: 'agreement_page') ||
        create(name: 'agreement_page', value: default_agreement_text)
    end

    def agreement_page=(value)
      agreement_page.update(value:)
    end

    def help_page
      find_or_create_by(name: 'help_page')
    end

    def help_page=(value)
      help_page.update(value:)
    end

    def terms_page
      find_by(name: 'terms_page') ||
        create(name: 'terms_page', value: default_terms_text)
    end

    def terms_page=(value)
      terms_page.update(value:)
    end

    def default_agreement_text
      ERB.new(
        IO.read(
          Hyrax::Engine.root.join('app', 'views', 'hyrax', 'content_blocks', 'templates', 'agreement.html.erb')
        )
      ).result
    end

    def default_terms_text
      ERB.new(
        IO.read(
          Hyrax::Engine.root.join('app', 'views', 'hyrax', 'content_blocks', 'templates', 'terms.html.erb')
        )
      ).result
    end
  end
end
# rubocop:enable Metrics/ClassLength
