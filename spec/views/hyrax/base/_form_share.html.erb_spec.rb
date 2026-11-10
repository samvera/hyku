# frozen_string_literal: true

# Hyrax saves a changed or removed grant only for rows that name their agent, so these
# check which rows name it: editable grants do, and grants set elsewhere must not.
RSpec.describe 'hyrax/base/_form_share.html.erb', type: :view do
  let(:depositor) { create(:user) }
  let(:reader) { create(:user) }
  let!(:admin_group) { FactoryBot.create(:admin_group) }
  let(:work) do
    FactoryBot.valkyrie_create(:generic_work_resource, :public,
                               depositor: depositor.user_key,
                               edit_users: [depositor],
                               read_users: [reader],
                               edit_groups: [admin_group.name],
                               with_index: false)
  end
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: work).tap(&:prepopulate!) }
  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:agent_names) { page.all('input[name$="[name]"]', visible: false).map(&:value) }

  def render_partial
    view.simple_form_for(form, url: '/update') do |f|
      concat render(partial: 'hyrax/base/form_share', locals: { f: f })
    end
  end

  before do
    allow(view).to receive(:link_to_profile).and_return(depositor.user_key)
    allow(view).to receive(:current_ability).and_return(Ability.new(depositor))
  end

  it "sends each editable grant's agent, so a change or removal saves" do
    render_partial
    row = page.find('tr', text: reader.user_key)

    expect(row).to have_select
    expect(row).to have_field(type: 'hidden', with: 'person', name: /\[permissions_attributes\]\[\d+\]\[type\]/)
    expect(row).to have_field(type: 'hidden', with: reader.user_key, name: /\[permissions_attributes\]\[\d+\]\[name\]/)
  end

  it 'leaves out the public, depositor and admin group grants, which are set elsewhere' do
    render_partial

    expect(agent_names).to contain_exactly(reader.user_key)
  end

  it 'shows the admin group read-only' do
    render_partial
    row = page.find('tr', text: /\A\s*Admin\s*\z/)

    expect(row).not_to have_select
    expect(row).not_to have_button
  end

  it 'starts new grants after the rows it leaves out' do
    render_partial

    expect(page).to have_css("#file_permissions[data-next-index='#{form.permissions.size}']")
  end

  context "with a grant the user can't change" do
    before { allow_any_instance_of(Hyrax::EditPermissionsService).to receive(:cannot_edit_permissions?).and_return(true) }

    it 'sends it unchanged, without a control that would change it' do
      render_partial
      row = page.find('tr', text: reader.user_key)

      expect(row).not_to have_select
      expect(row).not_to have_button
      expect(row).to have_field(type: 'hidden', with: 'read', name: /\[access\]/)
    end
  end
end
