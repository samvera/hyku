# frozen_string_literal: true

# OVERRIDE FILE from Hyrax v2.9.0
# Override this class using #class_eval to avoid needing to copy the entire file over from
# the dependency. For more info, see the "Overrides using #class_eval" section in the README.
require_dependency Hyrax::Engine.root.join('app', 'presenters', 'hyrax', 'collection_presenter').to_s
Hyrax::CollectionPresenter.class_eval do
  # Terms is the list of fields displayed by
  # app/views/collections/_show_descriptions.html.erb
  # OVERRIDE Hyrax - removed size
  def self.terms
    %i[ total_items
        resource_type
        creator contributor
        keyword license
        publisher
        date_created
        subject language
        identifier
        based_near
        related_url]
  end

  def [](key)
    case key
    when :total_items
      total_items
    else
      solr_document.send key
    end
  end
end
