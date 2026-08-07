# frozen_string_literal: true

RSpec.describe 'themes/institutional_repository/_controls.html.erb', type: :view do
  before do
    allow(view).to receive(:admin_host?).and_return(false)
    stub_template '_user_util_links.html.erb' => ''

    render partial: 'themes/institutional_repository/controls'
  end

  it 'renders the root menu links' do
    expect(rendered).to have_css('li.nav-item a.nav-link', count: 4)
  end

  it 'keeps the nav class the appearance color rules target' do
    # The appearance styles color nav links via `.nav.navbar-nav > li.nav-item
    # > a.nav-link` (default #333333, tenant-configurable). Without the `nav`
    # class Bootstrap's `.navbar-light` rgba(0,0,0,.5) wins instead, which
    # composites to 3.91:1 on bg-light - a serious axe color-contrast
    # violation on all four links. The hyrax gem's _controls.html.erb this
    # partial overrides uses `nav navbar-nav`.
    expect(rendered).to have_css('ul.nav.navbar-nav')
  end
end
