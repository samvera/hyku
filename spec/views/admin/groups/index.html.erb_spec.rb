RSpec.describe 'admin/groups/index', type: :view do
  context 'groups index page' do
    let(:group_1) { FactoryBot.create(:group) }
    let(:group_2) { FactoryBot.create(:group) }
    let(:groups) { double('groups') }

    before do
      allow(groups).to receive(:each).and_yield(group_1).and_yield(group_2)
      allow(groups).to receive(:total_pages).and_return(1)
      allow(groups).to receive(:current_page).and_return(1)
      allow(groups).to receive(:limit_value).and_return(10)
      assign(:groups, groups)
      render
    end

    it 'reports the total number of groups' do
      expect(rendered).to have_selector('b', text: '2 groups')
    end

    it 'renders a list of accounts' do
      expect(rendered).to have_selector('td', text: group_1.name)
      expect(rendered).to have_selector('td', text: group_1.number_of_users)
      expect(rendered).to have_selector('td', text: group_1.created_at.to_date.to_formatted_s(:standard))

      expect(rendered).to have_selector('td', text: group_2.name)
      expect(rendered).to have_selector('td', text: group_2.number_of_users)
      expect(rendered).to have_selector('td', text: group_2.created_at.to_date.to_formatted_s(:standard))
    end

    it 'has a button to create a new group' do
      expect(rendered).to have_selector('a', class: ['btn', 'new-group'])
    end

    it 'has a group search control' do
      expect(rendered).to have_selector('input', class: 'list-scope__query')
      expect(rendered).to have_selector('input', class: 'list-scope__submit')
    end

    it 'has a pagination select control' do
      expect(rendered).to have_selector('select', class: 'js-per-page__select')
      expect(rendered).to have_selector('input', class: 'js-per-page__submit')
    end
  end
end
