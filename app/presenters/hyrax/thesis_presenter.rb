# Generated via
#  `rails generate hyrax:work Thesis`
module Hyrax
  class ThesisPresenter < Hyrax::WorkShowPresenter
  end
end

# Default properties for the show page:
# By default, the new properties will NOT be displayed on the show page for
# works of this type. If you do nothing, the properties displayed on the show page is
# guided by Hyrax::WorkShowPresenter class. 
# Look for the property names delegated to the solr_document near the top of the
# file.
# ref: 
# https://github.com/samvera/hyrax/blob/main/app/presenters/hyrax/work_show_presenter.rb#L22-L24
# 
# In addition to delegating the new properties, you will also need to retrieve the
# properties from solr by modifying the solr_document.rb file, and you will need to add
# the properties to the show page by adding them to the
# app/views/curation_concerns/base/_attribute_rows.html.erb file. 
# ref gist for additional support: 
# https://gist.github.com/ShanaLMoore/df8562ab13f15ab3a7cc347d61431944#modifying-the-show-page
# 
# EXERCISE: display the new properties on the show page.
