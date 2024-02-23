# frozen_string_literal: true

module GroupNavigationHelper
  def navigation_presenter
    @navigation_presenter ||= Hyku::Admin::Group::NavigationPresenter.new(params: params)
  end
end
