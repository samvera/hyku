# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Tenant Management', multitenant: true do
  let(:superadmin) { create(:superadmin) }
  let(:account) do
    create(:account, name: 'Existing Institution').tap do |created_account|
      created_account.create_solr_endpoint(url: 'http://localhost:8080/solr')
      created_account.create_fcrepo_endpoint(url: 'http://localhost:8080/fcrepo')
    end
  end

  before do
    allow(Flipflop).to receive(:read_only?).and_return(false)
    allow(Account).to receive(:from_request).and_return(account)
    login_as superadmin, scope: :user
    allow(Apartment::Tenant).to receive(:switch) do |&block|
      block.call
    end
    allow_any_instance_of(Account).to receive(:find_or_schedule_jobs)
    allow_any_instance_of(Account).to receive(:switch!).and_return(true)
    account.admin_emails = [superadmin.email]
    allow(CreateAccountInlineJob).to receive(:perform_now).and_return(true)
    allow(Hyrax::AdminSetCreateService).to receive(:find_or_create_default_admin_set)
      .and_return(instance_double(Hyrax.config.admin_set_class, id: 'admin-set-id'))
  end

  around do |example|
    default_host = Capybara.default_host
    Capybara.default_host = Capybara.app_host || "http://#{Account.admin_host}"
    example.run
    Capybara.default_host = default_host
  end

  it 'can create, edit, and delete a tenant account' do
    visit new_proprietor_account_path
    fill_in 'Short name', with: 'testtenant'
    within('.account-form') do
      click_button
    end
    expect(page).to have_content('testtenant')
    click_link 'Edit Account'
    check 'Is public'
    click_button 'Save changes'
    visit edit_proprietor_account_path(Account.find_by!(name: 'testtenant'))
    expect(page).to have_checked_field('Is public')
    visit proprietor_accounts_path
    within('tr', text: 'testtenant') do
      click_link 'Delete'
    end
    expect(page).not_to have_content('testtenant')
  end

  it 'can invite and remove tenant administrators' do
    create(:user, email: 'admin2@example.com')
    visit proprietor_accounts_path
    within('tr', text: account.tenant) do
      click_link 'Manage'
    end
    fill_in 'add_form_account_admin_emails', with: 'admin2@example.com'
    admin_form = find('#add_form_account_admin_emails').find(:xpath, './ancestor::form[1]')
    within(admin_form) do
      click_button 'Add Admin'
    end
    expect(page).to have_content('admin2@example.com')
    within('#current-admins-tab tr', text: 'admin2@example.com') do
      find('input[type="submit"][value="Remove Admin"]', visible: false).click
    end
    within('#current-admins-tab') do
      expect(page).not_to have_content('admin2@example.com')
    end
  end

  it 'can filter/search tenants and users' do
    visit proprietor_accounts_path
    expect(page).to have_content(account.tenant)
    visit proprietor_users_path
    expect(page).to have_content(superadmin.email)
  end

  it 'redirects an unauthenticated visitor to the login page with a not-authorized flash' do
    logout(:user)
    visit proprietor_accounts_path
    expect(page).to have_current_path(%r{/users/sign_in})
    expect(page).to have_content('You are not authorized to access this page.')
  end

  it 'lists tenant accounts with UUID, CNAME, and Manage/Edit/Delete actions' do
    visit proprietor_accounts_path
    within('table.datatable thead') do
      expect(page).to have_content('Tenant (UUID)')
      expect(page).to have_content('CNAME')
      expect(page).to have_content('Actions')
    end
    within('tr', text: account.tenant) do
      expect(page).to have_link('Manage')
      expect(page).to have_link('Edit')
      expect(page).to have_link('Delete')
    end
  end

  it 'offers a cancel link and rejects a blank short name on the new account form' do
    visit new_proprietor_account_path
    expect(page).to have_link('Cancel', href: proprietor_accounts_path)
    within('.account-form') do
      click_button
    end
    expect(page).to have_content('prohibited this repository from being saved')
    expect(page).to have_field('Short name')
  end

  it 'shows the tenant cname, edit/cancel links, and admin tabs on the manage page' do
    visit proprietor_accounts_path
    within('tr', text: account.tenant) do
      click_link 'Manage'
    end
    expect(page).to have_content(account.cname)
    expect(page).to have_link('Edit Account')
    expect(page).to have_link('Cancel', href: proprietor_accounts_path)
    expect(page).to have_content('Current Account Administrators')
    expect(page).to have_content('All Users')
  end

  it 'renders the editable account fields and a cancel link on the edit form' do
    visit edit_proprietor_account_path(account)
    expect(page).to have_field('Is public')
    expect(page).to have_field('Tenant UUID', readonly: true)
    expect(page).to have_field('Primary Domain Name', readonly: true)
    expect(page).to have_content('Solr Endpoint')
    unless Hyrax.config.disable_wings
      expect(page).to have_content('Fedora Endpoint')
      expect(page).to have_field('Base Path')
    end
    expect(page).to have_link('Cancel', href: proprietor_accounts_path)
  end
end



# ## Global Tenant Accounts Index Page (Admin only)
# [Back to TOC](#table-of-contents)

# ![image15](https://github.com/samvera/hyku/assets/19597776/7f70f45f-dddf-4a40-9583-d71f664294b0)

# ### As a user:

# - [ ] If I try to access this page (as a non logged-in admin), I am redirected to the Log in page with a flash message saying “You are not authorized to access this page.”
# ### As an admin:

# - [ ] I can see a table listing all of the tenant accounts, including their:
#   - [ ] UUID
#   - [ ] Cname
#   - [ ] Actions (Manage, Edit, Delete)
#     - [ ] I can click Manage, which directs me to the Manage Account page
#     - [ ] I can click Edit, which directs me to the Editing Account form
#     - [ ] I can click Delete, which removes that tenant account
# - [ ] I can filter through the tenant accounts using the search bar
# - [ ] I can click Create a new account, which directs me to the Create a new repository form

# ## Global Tenant Account New Page (Admin only)
# [Back to TOC](#table-of-contents)

# ![image62](https://github.com/samvera/hyku/assets/19597776/d6cbb942-4d04-4f59-a5d6-53a1476ded28)

# ### As an admin:

# - [ ] I can see a form to create a new tenant account
#   - [ ] There is a field for Short name (Cname)
#   - [ ] The form will not submit if the input is empty or invalid
# - [ ] I can click Save, which saves the new tenant and directs me to the Manage Account form
# - [ ] I can click on the link to Cancel, which directs me back to the tenant Accounts page

# ## Global Tenant Account Manage Page (Admin only)
# [Back to TOC](#table-of-contents)

# ![image23](https://github.com/samvera/hyku/assets/19597776/126e80b6-bfb9-4ab0-9c19-8a2e26d45f90)

# ### As an admin:

# - [ ] I can see the Cname of the tenant account I selected to manage
# - [ ] I can click Edit Account, which directs me to the Editing Account form
# - [ ] I can see a form to invite new administrators to this specific tenant account via email
#   - [ ] The form will not submit if the input is empty or invalid
#   - [ ] The entered email does **not** have to be linked to an existing account in order to be submitted successfully
#   - [ ] I can click Add, which adds the user to the list of Current Account Administrators
# - [ ] I can click Cancel, which directs me to the tenant Accounts page
# - [ ] I can see a list of admin users for that tenant account under the Current Account Administrators tab
#   - [ ] I can click Remove, which removes the admin user from that tenant
# - [ ] I can see a list of all users under the All Users tab
#   - [ ] I can click Add, which adds the user to the Current Account Administrators

# ## Global Tenant Account Edit Page (Admin only)
# [Back to TOC](#table-of-contents)

# ![image3](https://github.com/samvera/hyku/assets/19597776/fd1c45fd-b3a0-453a-add4-a29f5c41b96b)

# ### As an admin:

# - [ ] I can check/uncheck a box for Is public
#   - [ ] When this box is checked, the tenant is visible to the public from the Global Index page
# - [ ] I can see a form that contains the following attributes (and corresponding values) of the selected Tenant account:
#   - [ ] Tenant UUID (**Non-modifiable**) (required)
#   - [ ] Tenant CNAME (required)
#   - [ ] Solr Endpoint URL
#   - [ ] Fedora Endpoint URL
#   - [ ] Fedora Endpoint Base Path
# - [ ] I can click Save changes, which saves my changes and directs me to the Manage Account page
# - [ ] I can click Cancel, which directs me to the tenant Accounts page
