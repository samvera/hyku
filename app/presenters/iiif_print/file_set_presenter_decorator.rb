# frozen_string_literal: true

# OVERRIDE IiifPrint v3 to hide the re-split button.
#   Delete when splitting issue is resolved.
#   see https://github.com/notch8/palni_palci_knapsack/issues/80#issuecomment-2632366138
module IiifPrint
  module FileSetPresenterDecorator
    def show_split_button?
      false
    end
  end
end
Hyrax::FileSetPresenter.prepend(IiifPrint::FileSetPresenterDecorator)