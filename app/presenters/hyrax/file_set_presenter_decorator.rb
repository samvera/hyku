# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to add custom metadata partial for file set show page
module Hyrax
  module FileSetPresenterDecorator
    def show_partials
      super + ['metadata']
    end
  end
end

Hyrax::FileSetPresenter.prepend(Hyrax::FileSetPresenterDecorator)
