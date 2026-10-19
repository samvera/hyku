<a id="table-of-contents"></a>
## Table of Contents
- [Global Index / Institution List Page](#global-index--institution-list-page)
- [Global Administrator / User Login Page](#global-administrator--user-login-page)
- [Global Sign Up Page](#global-sign-up-page)
- [Global Forgot your Password? Page](#global-forgot-your-password-page)
- [Change your password page](#change-your-password-page)
- [Global Tenant Accounts Index Page (Admin only)](#global-tenant-accounts-index-page-admin-only)
- [Global Tenant Account New Page (Admin only)](#global-tenant-account-new-page-admin-only)
- [Global Tenant Account Manage Page (Admin only)](#global-tenant-account-manage-page-admin-only)
- [Global Tenant Account Edit Page (Admin only)](#global-tenant-account-edit-page-admin-only)
- [Global Users Index Page (Admin only)](#global-users-index-page-admin-only)
- [Global Users New Page (Admin only)](#global-users-new-page-admin-only)
- [Global Users Manage Page (Admin only)](#global-users-manage-page-admin-only)
- [Global Users Edit Page (Admin only)](#global-users-edit-page-admin-only)
- [Homepage](#homepage)
- [Contact Page](#contact-page)
- [Catalog (Search Results) Page](#catalog-search-results-page)
- [Collection Show Page](#collection-show-page)
- [Work Show Page](#work-show-page)
- [FileSet Show Page](#fileset-show-page)
- [Dashboard Page](#dashboard-page)
- [Dashboard Page (Admin)](#dashboard-page-admin)
- [Profile Page](#profile-page)
- [Profile Edit Page](#profile-edit-page)
- [Notifications Page](#notifications-page)
- [Transfers Page](#transfers-page)
- [Manage Proxies Page](#manage-proxies-page)
- [Dashboard My Collections Index Page](#dashboard-my-collections-index-page)
- [Dashboard Collection New Page](#dashboard-collection-new-page)
- [Dashboard Collection Edit Page](#dashboard-collection-edit-page)
- [Dashboard Collection Show Page](#dashboard-collection-show-page)
- [Dashboard My Works Index Page](#dashboard-my-works-index-page)
- [Dashboard Works New by Batch Page](#dashboard-works-new-by-batch-page)
- [Dashboard Work New Page](#dashboard-work-new-page)
- [Dashboard Work Edit Page](#dashboard-work-edit-page)
- [Review Submissions Page](#review-submissions-page)
- [Manage Users Page](#manage-users-page)
- [Manage Groups Index Page](#manage-groups-index-page)
- [Manage Groups New Page](#manage-groups-new-page)
- [Manage Groups Edit Page](#manage-groups-edit-page)
- [Manage Embargoes Index Page](#manage-embargoes-index-page)
- [Manage Embargoes Edit Page](#manage-embargoes-edit-page)
- [Manage Embargoes Deactivate Page](#manage-embargoes-deactivate-page)
- [Manage Leases Index Page](#manage-leases-index-page)
- [Manage Leases Edit Page](#manage-leases-edit-page)
- [Manage Leases Deactivate Page](#manage-leases-deactivate-page)
- [Settings → Labels Page](#settings--labels-page)
- [Settings → Appearance Page](#settings--appearance-page)
- [Settings → Collection Types Index Page](#settings--collection-types-index-page)
- [Settings → Collection Types New Page](#settings--collection-types-new-page)
- [Settings → Collection Types Edit Page](#settings--collection-types-edit-page)
- [Settings → Pages Page](#settings--pages-page)
- [Settings → Content Block](#settings--content-block)
- [Settings → Features Page](#settings--features-page)
- [Workflow Roles Page](#workflow-roles-page)

## Global Index / Institution List Page
[Back to TOC](#table-of-contents)

![image4](https://github.com/samvera/hyku/assets/19597776/4e6c6681-39e3-491a-ab7d-64f995d775b4)

### As a non-signed in user:

- [ ] I can see a list of each institution
  - [ ] Each institution has a display of their theme logo (or a placeholder if there is no logo)
  - [ ] I can click on the link for each institution, which directs me to the tenant for that institution
- [ ] I can click on the link to Administrator login (in the footer), which directs me to the Log in form
- [ ] I can select my preferred language from the Language dropdown menu
  - [ ] Selecting a language only sets the language for the current site, not for each of the individual tenants

![image39](https://github.com/samvera/hyku/assets/19597776/005910e7-8fbd-4c27-a9d4-a6cc07f34820)

### As a signed-in administrator:

- [ ] I can see a list of each institution
  - [ ] Each institution has a display of their theme logo (or a placeholder if there is no logo)
  - [ ] I can click on the link for each institution, which directs me to the tenant for that institution
- [ ] I can click Logout, which logs me out and directs me back to the Global Index page
- [ ] I can select my preferred language from the Language dropdown menu
  - [ ] Selecting a language only sets the language for the current site, not for each of the individual tenants
- [ ] I can click on Accounts, which directs me to the Accounts page for the tenants
- [ ] I can click on Users, which directs me to the Manage Users page for the users

**Spec coverage**

- _Knapsack only (not tested in base Hyku): the institution list, each institution's theme logo or placeholder,
  and the link to each institution's tenant, in both the non-signed-in and administrator lists. Base Hyku's
  global index (app/views/splash/index.html.erb) does not list tenants._
- [global_index_spec.rb](spec/features/global_index_spec.rb)
  - shows tenant administration links to a signed-in superadmin
  - as a non-signed-in visitor offers an Administrator login link in the footer that leads to the sign-in form
  - as a non-signed-in visitor offers a Language dropdown for choosing the display language
  - as a non-signed-in visitor sets the language only for the current site's links and does not store it
  - as a signed-in superadmin links Accounts to the tenant accounts page
  - as a signed-in superadmin links Users to the manage users page
  - as a signed-in superadmin offers a Language dropdown to a signed-in administrator
  - as a signed-in superadmin sets the language only for the current site's links and does not store it

## Global Administrator / User Login Page
[Back to TOC](#table-of-contents)

![image55](https://github.com/samvera/hyku/assets/19597776/6f43db4a-8a11-457a-91b7-28004ba864ab)

- [ ] I can see a form to enter an email and password
  - [ ] The form validates the format of my email
  - [ ] The form will only submit successfully if my account already exists
- [ ] I can check/uncheck a Remember me box
  - [ ] When this box is checked, my username will be saved on the form the next time I log in
- [ ] I can click Log in, which logs me in and directs me to the Global Index page
- [ ] I can click on the link to Sign up, which directs me to the Create a new account form
- [ ] I can click on the link to Forgot your password?, which directs me to the Forgot your password? form

**Spec coverage**

- [global_authentication_spec.rb](spec/features/global_authentication_spec.rb)
  - Log in page shows an email field (type=email), a password field, a Remember me box and a Log in button
  - Log in page rejects an email that has no account and stays on the form
  - Log in page rejects a malformed email
  - Log in page rejects the wrong password for an existing account
  - Log in page logs in with valid credentials and lands on the Global Index
  - Log in page sets the remember cookie only when Remember me is checked
  - Log in page links Forgot your password? to the Forgot your password form
  - Log in page links Sign up to the Create a new account form
  - Log in page hides the Sign up link when the request is on the global tenant

## Global Sign Up Page
[Back to TOC](#table-of-contents)

![image24](https://github.com/samvera/hyku/assets/19597776/c61751bc-f91d-4c79-847a-e780264ab3d6)

### As a user:

- [ ] I can see a form to Create a new account that validates the following inputs:
  - [ ] Your Name
  - [ ] Email Address
  - [ ] Password
  - [ ] Password confirmation
  - [ ] The form will not submit if any of the inputs is missing or invalid
- [ ] I can click Create account, which registers me as a new user and directs me to the Global Index page
- [ ] I can click on the link to Log in, which directs me to the Log in form
- [ ] I can click on the link to Forgot your password?, which directs me to the Forgot your password? form
- [ ] I can click on the link to Administrator login (in the footer), which directs me to the Log in form

**Spec coverage**

- [global_authentication_spec.rb](spec/features/global_authentication_spec.rb)
  - Sign up page shows required Your Name, Email address, Password and Password confirmation inputs
  - Sign up page does not register anyone when the required inputs are missing
  - Sign up page does not register anyone with an invalid email, short password or mismatched confirmation
  - Sign up page rejects an email that is already registered
  - Sign up page registers a new user, signs them in and lands on the Global Index
  - Sign up page links Log in to the Log in form
  - Sign up page links Forgot your password? to the Forgot your password form
  - Sign up page links Administrator login in the footer to the Log in form _(pending/skipped: known gap)_

## Global Forgot your Password? Page
[Back to TOC](#table-of-contents)

![image32](https://github.com/samvera/hyku/assets/19597776/178e82b8-8643-4abb-b82f-3e5b51abd772)

### As a user:

- [ ] I can see a form with an input for my Email
  - [ ] The form will not submit if the Email is empty or improperly formatted
  - [ ] The form will only submit if an account with my email already exists
- [ ] I can click Send me reset password instructions, which sends me an email with instructions for resetting my password
  - [ ] When I receive my password reset email, I can click on the link to “Change my password”, which directs me to the Change your password form
    * Found in [https://mailtrap.io/inboxes](https://mailtrap.io/inboxes)
- [ ] I can click on the link to Log in, which directs me to the Log in form
- [ ] I can click on the link to Sign up, which directs me to the Create your account form
- [ ] I can click on the link to Administrator login (in the footer), which directs me to the Log in form

**Spec coverage**

- [global_authentication_spec.rb](spec/features/global_authentication_spec.rb)
  - Forgot your password page shows an Email input
  - Forgot your password page rejects a blank email without sending anything
  - Forgot your password page rejects an email with no account (including a malformed one) without sending anything
  - Forgot your password page emails reset instructions whose Change my password link opens the Change your password form
  - Forgot your password page links Log in to the Log in form
  - Forgot your password page links Sign up to the Create a new account form
  - Forgot your password page links Administrator login in the footer to the Log in form _(pending/skipped: known gap)_

## Change your password page
[Back to TOC](#table-of-contents)

![image5](https://github.com/samvera/hyku/assets/19597776/708604aa-814b-4bd1-a5ce-834696315ea1)

### As a user:

- [ ] I can see a form to change my password
  - [ ] There is a field for New password
  - [ ] There is a field for Confirm new password
  - [ ] The form will not submit if the password is too short or if the password fields do not match
- [ ] I can click Change my password, which sets my new password and directs me to the Global Index page
- [ ] I can click on the link to Log in, which directs me to the Log in form
- [ ] I can click on the link to Sign up, which directs me to the Create your account form
- [ ] I can click on the link to Administrator login (in the footer), which directs me to the Log in form

**Spec coverage**

- [global_authentication_spec.rb](spec/features/global_authentication_spec.rb)
  - Change your password page shows New password and Confirm new password fields
  - Change your password page rejects a password that is too short
  - Change your password page rejects a confirmation that does not match
  - Change your password page changes the password, signs me in on the Global Index, and the new password works for log in
  - Change your password page links Log in to the Log in form
  - Change your password page links Sign up to the Create a new account form
  - Change your password page links Administrator login in the footer to the Log in form _(pending/skipped: known gap)_

## Global Tenant Accounts Index Page (Admin only)
[Back to TOC](#table-of-contents)

![image15](https://github.com/samvera/hyku/assets/19597776/7f70f45f-dddf-4a40-9583-d71f664294b0)

### As a user:

- [ ] If I try to access this page (as a non logged-in admin), I am redirected to the Log in page with a flash message saying “You are not authorized to access this page.”
### As an admin:

- [ ] I can see a table listing all of the tenant accounts, including their:
  - [ ] UUID
  - [ ] Cname
  - [ ] Actions (Manage, Edit, Delete)
    - [ ] I can click Manage, which directs me to the Manage Account page
    - [ ] I can click Edit, which directs me to the Editing Account form
    - [ ] I can click Delete, which removes that tenant account
- [ ] I can filter through the tenant accounts using the search bar
- [ ] I can click Create a new account, which directs me to the Create a new repository form

**Spec coverage**

- [admin_tenant_management_spec.rb](spec/features/admin_tenant_management_spec.rb)
  - redirects an unauthenticated visitor to the login page with a not-authorized flash
  - lists tenant accounts with UUID, CNAME, and Manage/Edit/Delete actions
  - navigates from the accounts index to the Manage, Edit and Create new account pages
  - filters the tenant accounts with the search bar

## Global Tenant Account New Page (Admin only)
[Back to TOC](#table-of-contents)

![image62](https://github.com/samvera/hyku/assets/19597776/d6cbb942-4d04-4f59-a5d6-53a1476ded28)

### As an admin:

- [ ] I can see a form to create a new tenant account
  - [ ] There is a field for Short name (Cname)
  - [ ] The form will not submit if the input is empty or invalid
- [ ] I can click Save, which saves the new tenant and directs me to the Manage Account form
- [ ] I can click on the link to Cancel, which directs me back to the tenant Accounts page

**Spec coverage**

- [admin_tenant_management_spec.rb](spec/features/admin_tenant_management_spec.rb)
  - can create, edit, and delete a tenant account
  - offers a cancel link and rejects a blank short name on the new account form
  - rejects a short name that is already in use
  - rejects a short name with a trailing dot _(pending/skipped: known gap)_

## Global Tenant Account Manage Page (Admin only)
[Back to TOC](#table-of-contents)

![image23](https://github.com/samvera/hyku/assets/19597776/126e80b6-bfb9-4ab0-9c19-8a2e26d45f90)

### As an admin:

- [ ] I can see the Cname of the tenant account I selected to manage
- [ ] I can click Edit Account, which directs me to the Editing Account form
- [ ] I can see a form to invite new administrators to this specific tenant account via email
  - [ ] The form will not submit if the input is empty or invalid
  - [ ] The entered email does **not** have to be linked to an existing account in order to be submitted successfully
  - [ ] I can click Add, which adds the user to the list of Current Account Administrators
- [ ] I can click Cancel, which directs me to the tenant Accounts page
- [ ] I can see a list of admin users for that tenant account under the Current Account Administrators tab
  - [ ] I can click Remove, which removes the admin user from that tenant
- [ ] I can see a list of all users under the All Users tab
  - [ ] I can click Add, which adds the user to the Current Account Administrators

**Spec coverage**

- [admin_tenant_management_spec.rb](spec/features/admin_tenant_management_spec.rb)
  - can invite and remove tenant administrators
  - shows the tenant cname, edit/cancel links, and admin tabs on the manage page
  - inviting administrators on the Manage page invites an email that has no user yet and lists it as a current administrator
  - lists every user under All Users and its Add makes that user an administrator

## Global Tenant Account Edit Page (Admin only)
[Back to TOC](#table-of-contents)

![image3](https://github.com/samvera/hyku/assets/19597776/fd1c45fd-b3a0-453a-add4-a29f5c41b96b)

### As an admin:

- [ ] I can check/uncheck a box for Is public
  - [ ] When this box is checked, the tenant is visible to the public from the Global Index page
- [ ] I can see a form that contains the following attributes (and corresponding values) of the selected Tenant account:
  - [ ] Tenant UUID (**Non-modifiable**) (required)
  - [ ] Tenant CNAME (required)
  - [ ] Solr Endpoint URL
  - [ ] Fedora Endpoint URL
  - [ ] Fedora Endpoint Base Path
- [ ] I can click Save changes, which saves my changes and directs me to the Manage Account page
- [ ] I can click Cancel, which directs me to the tenant Accounts page

**Spec coverage**

- _Knapsack only (not tested in base Hyku): "When this box is checked, the tenant is visible to the public from
  the Global Index page", because the tenant list on the Global Index is a knapsack feature._
- [admin_tenant_management_spec.rb](spec/features/admin_tenant_management_spec.rb)
  - renders the editable account fields and a cancel link on the edit form
  - shows the account values and saves edits back to the Manage Account page _(pending/skipped: known gap)_

## Global Users Index Page (Admin only)
[Back to TOC](#table-of-contents)

![image81](https://github.com/samvera/hyku/assets/19597776/d237def8-78bf-4d1f-b307-4aaa3c5c45c1)

### As an admin:

- [ ] I can see a table listing all users across all tenants
- [ ] The following attributes of each user are displayed in separate columns:
  - [ ] Email
  - [ ] Display name
  - [ ] Department
  - [ ] Title
  - [ ] Affiliation
  - [ ] Superadmin
  - [ ] Actions (Manage, Edit, Become, Delete)
    - [ ] I can click Manage, which directs me to the Manage User page
    - [ ] I can click Edit, which directs me to the Edit User form
    - [ ] I can click Become, which signs me out of my account and into the account of that user
    - [ ] I can click Delete, which removes that user
- [ ] I can filter through users using the search box
- [ ] I can click Create New, directing me to the Create a new user form

**Spec coverage**

- [global_users_management_spec.rb](spec/features/global_users_management_spec.rb)
  - index page lists every user with their attributes in separate columns
  - index page goes to the Manage User page from Manage
  - index page goes to the Edit User form from Edit
  - index page goes to the Create a new user form from Create New
  - index page offers Become to sign in as another user _(pending/skipped: known gap)_
  - index page with javascript deletes a user after confirming
  - index page with javascript filters the users table with the search box

## Global Users New Page (Admin only)
[Back to TOC](#table-of-contents)

![image40](https://github.com/samvera/hyku/assets/19597776/01dc1c7c-5eef-4eb9-80d7-2e8d9b8abb32)

### As an admin:

- [ ] I see a form where I can assign attributes and create a new user
  - [ ] The form will fail to submit if any of the entered attributes are invalid
- [ ] I can click Save, which saves the new user and directs me back to the Manage Users page
- [ ] I can click Cancel, which directs me back to the Manage Users page

**Spec coverage**

- [global_users_management_spec.rb](spec/features/global_users_management_spec.rb)
  - new page creates a user on Save and returns to the users list
  - new page re-renders the form with errors when an attribute is invalid
  - new page returns to the users list on Cancel

## Global Users Manage Page (Admin only)
[Back to TOC](#table-of-contents)

![image10](https://github.com/samvera/hyku/assets/19597776/b4e9e8c6-1a10-486c-be8a-416275ec4f5d)

### As an admin:

- [ ] I can check the box to assign/unassign the superadmin role
  - [ ] When this box is checked, the user has the privileges of a superadmin
- [ ] I can click Update, which saves the changes and directs me back to the Manage Users page
- [ ] I can click Cancel, which directs me back to the Manage Users page
- [ ] I can click Edit, which directs me to the Edit User form

**Spec coverage**

- [global_users_management_spec.rb](spec/features/global_users_management_spec.rb)
  - manage page assigns the superadmin role with the checkbox and Update
  - manage page unassigns the superadmin role by clearing the checkbox
  - manage page returns to the users list on Cancel
  - manage page goes to the Edit User form from Edit

## Global Users Edit Page (Admin only)
[Back to TOC](#table-of-contents)

![image73](https://github.com/samvera/hyku/assets/19597776/607553e1-f02c-4de3-a5fb-af5bd68ccf4a)

### As an admin:

- [ ] I can see a form to edit attributes of the selected user
  - [ ] Display Name is filled in
  - [ ] Email address is filled in
- [ ] I can click Save changes, which saves my changes and directs me back to the Manage Users page
- [ ] I can click Cancel, directing me back to the Manage Users page

**Spec coverage**

- [global_users_management_spec.rb](spec/features/global_users_management_spec.rb)
  - edit page pre-fills the user's Display Name and Email address
  - edit page saves changes and returns to the users list
  - edit page returns to the users list on Cancel without saving

## Homepage
[Back to TOC](#table-of-contents)

![image18](https://github.com/samvera/hyku/assets/19597776/0c009033-4c68-4524-a7cb-ebe8cc7c5bac)

### As a user:

- [ ] I can click Login, which directs me to the Log in form
  - [ ] If I’m signed in, instead of the Login button I see my account’s display name (email address if display name isn’t present)
- [ ] I can select my preferred language from the Language dropdown menu
  - [ ] Selecting a language sets that language for the entire tenant
- [ ] I can click on the links to the Home, About, Help, Contact and Terms of Use static pages, directing me to their respective pages
- [ ] I can search the Work / Collection metadata from the search bar
  - [ ] If signed in, I can filter the search results using the dropdown adjacent to the Go button (All of Hyku Commons, My Works, My Collections)
- [ ] I can click Share Your Work, which directs me to the Log in form if I am not logged in
  - [ ] If I am already logged in, I am directed to the work creation form
- [ ] I can click on the Featured Works tab, which displays the works that have been featured*
- [ ] I can click on the Recently Uploaded tab, which displays the works that were recently uploaded*
- [ ] I can click on the Explore Collections tab, which displays a list of collections*
- [ ] I can click on the Featured Researcher tab, which displays the researcher who has been featured*
- [ ] I can click View all collections, which directs me to the Collections index page

* Only applies to objects I am authorized to view

**Spec coverage**

- [homepage_spec.rb](spec/features/homepage_spec.rb)
  - login and account name directs a visitor from Login to the Log in form
  - login and account name shows a signed-in user's display name instead of Login
  - login and account name falls back to the email address when the user has no display name
  - search bar searches work metadata and lists only matching works the visitor may see
  - search bar offers the All / My Works / My Collections scope only when signed in
  - search bar with javascript searches only my works when My Works is chosen
  - search bar with javascript searches only my collections when My Collections is chosen
  - Share Your Work directs a visitor who is not logged in to the Log in form
  - Share Your Work directs a logged-in depositor to the work creation form
  - tabs shows featured works, recent public uploads, featured collections and the featured researcher
  - tabs switches between the tabs
  - tabs lists all collections from View all collections
- [ui_ux_and_static_pages_spec.rb](spec/features/ui_ux_and_static_pages_spec.rb)
  - switches the interface language and keeps it across the tenant pages
  - navigates static pages: Home, About, Help, Terms, Contact

## Contact Page
[Back to TOC](#table-of-contents)

![image11](https://github.com/samvera/hyku/assets/19597776/0e453cc4-b44d-4ba4-b324-5fbcdce8bee8)

### As a user:

- [ ] I can see a notice above the form describing the kind of things to submit a Contact Form for
- [ ] I can select an option from the Issue Type dropdown menu:
  - [ ] Depositing content
  - [ ] Making changes to my content
  - [ ] Browsing and searching
  - [ ] Reporting a problem
  - [ ] General inquiry or request
- [ ] I can click Send to send the Contact Form
  - [ ] Form won’t send successfully if any of the fields are invalid

**Spec coverage**

- [contact_form_spec.rb](spec/features/contact_form_spec.rb)
  - submits the contact form for each issue type and validates errors
  - shows a notice above the form describing what to use the Contact Form for
  - offers each Issue Type option in the dropdown menu

## Catalog (Search Results) Page
[Back to TOC](#table-of-contents)

![image65](https://github.com/samvera/hyku/assets/19597776/6127f7ae-633d-4613-8b51-26268fb67efa)

### As a user:

- [ ] I can see a search bar
- [ ] I can customize the search results by selecting different filters (Sort by, number of records per page, layout)
- [ ] I can click Start Over, removing all active filters
- [ ] If there are multiple pages, I can see a pagination menu at the bottom of the page
- [ ] I can limit my search by selecting from the metadata dropdown menus on the left

**Spec coverage**

- [catalog_controls_spec.rb](spec/features/catalog_controls_spec.rb)
  - searches from the search bar and returns the matching work
  - customizes the search results by selecting different filters (Sort by, number of records per page, layout)
  - limits results with a facet menu and clears it via New Search
  - paginates when results span multiple pages

## Collection Show Page
[Back to TOC](#table-of-contents)

![image21](https://github.com/samvera/hyku/assets/19597776/112dcfb1-62e1-440c-9bec-214649939112)

### As a user:

- [ ] I can see the title of my collection along with some basic info (Visibility, Last Updated, etc)
- [ ] I can see a Collection Details table displaying collection-specific metadata
- [ ] I can see a section displaying the collection’s description along with its representative media
- [ ] I can search for records within this collection from the search bar
- [ ] I can see a list containing all works within this collection
  - [ ] I can filter through these works in various ways (Sort by, Results per page, Layout)

**Spec coverage**

- [collection_show_spec.rb](spec/features/collection_show_spec.rb)
  - the public collection show page shows collection metadata, description, and member works
  - the public collection show page searches within the collection
  - shows the visibility badge, item count, and Last Updated date in the header
  - shows the description next to the representative media
  - narrows the member list to the works matching the collection search
  - re-sorts the works with Sort by
  - changes how many works are shown with Results per page
  - switches the works layout with the view-type buttons

## Work Show Page
[Back to TOC](#table-of-contents)

![image16](https://github.com/samvera/hyku/assets/19597776/f1e0d1ff-66b3-45ad-8965-9ef578b7b32b)

### As a user:

- [ ] I can see the title of the work (as well as its visibility, deposited status, etc)
- [ ] I can see a IIIF media viewer
- [ ] I can see any relationships the work may have
- [ ] I can see a list of metadata specific to the work
- [ ] I can click on the social media icons to share the work on various social media platforms
- [ ] I can select a Citation to download from the Citations dropdown menu (EndNote, Zotero, Mendeley)
- [ ] I can see an Items table containing all the files associated with the work
  - [ ] I can see basic information for each item in the table (thumbnail, title, date uploaded, visibility, actions)
  - [ ] I can select an action from the Select an action dropdown menu
    - [ ] Edit
    - [ ] Versions
    - [ ] Delete
    - [ ] Download

### As an admin:

- [ ] I can also see buttons with actions related to the individual work:
  - [ ] Edit
  - [ ] Delete
  - [ ] Attach Child
    - [ ] Attach Work
    - [ ] Attach Image
  - [ ] Add to Collection
  - [ ] Feature (only if the work is set to Public visibility)

**Spec coverage**

- [work_show_actions_spec.rb](spec/features/work_show_actions_spec.rb)
  - the work show page as an administrator shows the Edit, Delete, Add to Collection, Feature and Attach Child controls
  - the work show page as an administrator hides the Feature action for a non-public work
  - the work show page as an administrator lists each attached file in the items table with its details and action menu
  - the work show page as an anonymous public user shows the title, visibility, metadata, relationships and citation affordances
  - the work show page as an anonymous public user offers EndNote, Zotero, and Mendeley citation downloads
  - the work show page as an anonymous public user downloads an EndNote citation of the work from the Citation menu
  - the work show page as an anonymous public user does not show administrative action controls
  - renders the IIIF media viewer for a work whose representative is an image
  - shows the workflow status badge for a work in a review workflow
  - shows no workflow status badge for a work outside any workflow
  - links the parent collection and parent work in the Relations card
  - documented gaps links to social-media share icons for the work _(pending/skipped: known gap)_

## FileSet Show Page
[Back to TOC](#table-of-contents)

![image26](https://github.com/samvera/hyku/assets/19597776/f7d9ad7b-954d-4a25-836e-8b132660c38f)

### As a user:

- [ ] I can see the file’s title, thumbnail and visibility
- [ ] I can download the file from the Download Image link
- [ ] I can see a table of File Details displaying basic information regarding the file
- [ ] I can see a table of User Activity relating to the depositor / file
- [ ] I can see icons to share the file on various social media platforms
### As an admin:

- [ ] I can click Edit this File to edit the file
- [ ] I can click Delete this File to delete the file
- [ ] I can generate single-use download links by clicking Single-Use Link to File

**Spec coverage**

- [fileset_show_and_actions_spec.rb](spec/features/fileset_show_and_actions_spec.rb)
  - the public FileSet show page shows the title, visibility, media, details, activity and social links
  - the admin FileSet controls shows the Edit, Delete, and Single-Use Link controls
  - the admin FileSet controls generates a single-use link that appears in the Single-Use Links table
  - the admin FileSet controls edits the file title and then deletes the file
  - no admin FileSet controls for anonymous visitors hides the Edit, Delete, and Single-Use Link controls
  - shows the thumbnail and Download image link for an image file

## Dashboard Page
[Back to TOC](#table-of-contents)

![image35](https://github.com/samvera/hyku/assets/19597776/f8eca63f-290c-480f-bdf5-26b482a57a02)

### As a user:

- [ ] I can see recent activity from my account
- [ ] I can see any notifications associated with my account
- [ ] I can see any current proxies I have
- [ ] I can see both sent and received transfer of ownership requests
- [ ] In the sidebar, I can see options/dropdown menus for
  - [ ] Activity
    - [ ] Repository Activity
      - [ ] Activity Summary
    - [ ] Your Activity
      - [ ] Profile
      - [ ] Notifications
      - [ ] Transfers
      - [ ] Manage Proxies
  - [ ] Repository Contents
    - [ ] Collections
    - [ ] Works
    - [ ] Importers
    - [ ] Exporters

**Spec coverage**

- [dashboard_and_admin_dashboard_spec.rb](spec/features/dashboard_and_admin_dashboard_spec.rb)
  - shows user dashboard with activity, notifications, proxies, and transfers
  - shows the user's own recent activity, notifications, proxies and transfers
  - shows the user sidebar Activity and Repository Contents navigation links
  - with a default admin set to deposit into shows Importers and Exporters to a regular user with deposit rights
  - with a default admin set to deposit into hides Importers and Exporters from a user who cannot create works

## Dashboard Page (Admin)
[Back to TOC](#table-of-contents)

![image75](https://github.com/samvera/hyku/assets/19597776/6b9dc5ca-f249-48d9-9bb3-4895c7917201)

### As an admin:

- [ ] I can see various site statistics, including:
  - [ ] Stats on number of users & visitors
  - [ ] Recent activity on Administrative Sets
  - [ ] User activity, Repository Growth, Repository Objects
- [ ] In the sidebar, I can see options/dropdowns for
  - [ ] Activity
    - [ ] Repository Activity
      - [ ] Activity Summary
      - [ ] System Status
    - [ ] Your activity
      - [ ] Profile
      - [ ] Notifications
      - [ ] Transfers
      - [ ] Manage Proxies
    - [ ] Reports
  - [ ] Repository Contents
    - [ ] Collections
    - [ ] Works
    - [ ] Importers
    - [ ] Exporters
  - [ ] Tasks
    - [ ] Review Submissions
    - [ ] Manage Users
    - [ ] Manage Groups
    - [ ] Manage Embargoes
    - [ ] Manage Leases
  - [ ] Configuration
    - [ ] Settings
      - [ ] Account
      - [ ] Labels
      - [ ] Appearance
      - [ ] Collection Types
      - [ ] Pages
      - [ ] Content Blocks
      - [ ] Features
      - [ ] Available Work Types
    - [ ] Workflow Roles

**Spec coverage**

- [dashboard_and_admin_dashboard_spec.rb](spec/features/dashboard_and_admin_dashboard_spec.rb)
  - shows admin dashboard with statistics and navigation
  - shows stats on the number of users and visitors _(pending/skipped: known gap)_
  - shows Workflow Roles under Configuration only when that menu item is enabled
  - shows the admin Repository Activity and Configuration > Settings submenu links
  - shows Bulkrax Importers and Exporters links under Repository Contents

## Profile Page
[Back to TOC](#table-of-contents)

![image68](https://github.com/samvera/hyku/assets/19597776/e96ff5ff-3328-4979-86bc-c2fabd51b3cc)

### As a user:

- [ ] I can see the date that I joined the site
- [ ] I can click on the link to Collections Created, directing me to a search results page of all of the collections that I have created
  - [ ] To the right, I can see the number of collections I have created
- [ ] I can click on the Works Created link, directing me to a search results page of all of the works that I have created
  - [ ] To the right, I can see the number of works I have created
  - [ ] Under Works created I can see
    - [ ] The number of Views
    - [ ] The number of Downloads
- [ ] I can see the email associated with my account
- [ ] I can click Edit Profile, directing me to the Edit Profile form  \

**Spec coverage**

- [profile_and_notifications_spec.rb](spec/features/profile_and_notifications_spec.rb)
  - displays join date, stats, email, and edit link on the profile show page
  - shows the summed number of views and downloads under Works created
  - Works created and Collections created shows the number of works and collections the user created
  - Works created and Collections created links Works created to a search of only the user's works _(pending/skipped: known gap)_
  - Works created and Collections created links Collections created to a search of only the user's collections _(pending/skipped: known gap)_

## Profile Edit Page
[Back to TOC](#table-of-contents)

![image48](https://github.com/samvera/hyku/assets/19597776/f1c5cf5b-885b-4798-8ded-5652ea1e079b)

### As a user:

- [ ] I can see a form to update my profile with the following inputs:
  - [ ] File input for profile picture
  - [ ] Delete picture checkbox
    - [ ] If this is checked, the profile picture is removed
  - [ ] ORCID profile
  - [ ] Twitter handle
  - [ ] Facebook handle
  - [ ] Google+ handle
- [ ] I can click Save Profile, which saves my information and directs me to the Profile page

**Spec coverage**

- [profile_and_notifications_spec.rb](spec/features/profile_and_notifications_spec.rb)
  - saves the profile and returns to the profile page
  - renders the profile picture, delete-picture, ORCID, Twitter, Facebook, and Google+ inputs
  - uploads a profile picture and removes it with Delete picture

## Notifications Page
[Back to TOC](#table-of-contents)

![image13](https://github.com/samvera/hyku/assets/19597776/88a81c38-9d78-4301-babc-538c237a76f0)

### As a user:

- [ ] I can click Delete All, deleting all of my notifications
- [ ] I can see a table listing all notifications associated with my account with the following attributes:
  - [ ] Date
  - [ ] Subject
  - [ ] Message
- [ ] I can delete individual notifications by clicking on the trash icon to the right
- [ ] I can filter through my notifications using the search bar
- [ ] I can see the total number of notifications
- [ ] I can see a pagination menu on the bottom right

**Spec coverage**

- [profile_and_notifications_spec.rb](spec/features/profile_and_notifications_spec.rb)
  - notifications lists notifications in a table with Date, Subject, and Message columns
  - notifications deletes an individual notification with its trash icon
  - notifications deletes all notifications with Delete All
  - notifications offers search, pagination, and a total count

## Transfers Page
[Back to TOC](#table-of-contents)

![image1](https://github.com/samvera/hyku/assets/19597776/352904b6-423d-4434-b768-23cb563a22ec)

### As a user:

- [ ] I can see all my Transfers Sent
  - [ ] Title
  - [ ] Date
  - [ ] To
  - [ ] Status
    - [ ] Pending Sent transfers can be cancelled by the sender before transfer request is accepted
  - [ ] Comments
- [ ] I can see all my Transfers Received
  - [ ] Contains same table columns as Transfers Sent, except “To” has been replaced with “From”
    - [ ] Status actions include:
      - [ ] Accept
        - [ ] Allow depositor to retain edit access
        - [ ] Remove depositor access
        - [ ] Authorize depositor as proxy
      - [ ] Reject

**Spec coverage**

- [transfers_and_proxies_spec.rb](spec/features/transfers_and_proxies_spec.rb)
  - as a user permitted to search for other users (user_reader role) sends an ownership transfer request from the works dashboard
  - with a real pending ownership transfer request shows the sender a Transfers Sent list with Title, Date, recipient, Status and Comments
  - with a real pending ownership transfer request lets the sender cancel a pending sent transfer
  - with a real pending ownership transfer request shows the recipient a Transfers Received list with a From column and Accept/Reject actions
  - with a real pending ownership transfer request lets the recipient reject a received transfer
  - with a real pending ownership transfer request lets the recipient accept a received transfer, retaining depositor edit access
  - with a real pending ownership transfer request lets the recipient accept a transfer and remove the depositor's access
  - with a real pending ownership transfer request lets the recipient accept a transfer and authorize the depositor as a proxy

## Manage Proxies Page
[Back to TOC](#table-of-contents)

![image38](https://github.com/samvera/hyku/assets/19597776/a6564c90-15a4-4aa1-aac9-f17c6d499a32)

### As a user:

- [ ] I can see a short description of what proxies are and how they work
- [ ] I see a search dropdown filter to find users I want to Authorize Proxies for my account
- [ ] I can see a list of all Current Proxies I have active on my account
  - [ ] I can see a Delete Proxy button to remove an active proxy

**Spec coverage**

- [transfers_and_proxies_spec.rb](spec/features/transfers_and_proxies_spec.rb)
  - as a user permitted to search for other users (user_reader role) can add and remove proxies
  - lets a regular user find another user in the Manage Proxies picker _(pending/skipped: known gap)_

## Dashboard My Collections Index Page
[Back to TOC](#table-of-contents)

![image77](https://github.com/samvera/hyku/assets/19597776/9af90c67-0f28-4ac4-b3e5-0a84b584f045)

### As a user:

- [ ] I can see the number of collections I own in the repository
- [ ] I can see a button to add a New Collection
- [ ] I can see several dropdowns to filter through collections
- [ ] I can see a search bar to search for specific collections
- [ ] I can see a table listing all collections I have permission to manage
- [ ] I can see basic information re. each individual collection:
  - [ ] Title
  - [ ] Type
  - [ ] Visibility
  - [ ] Items
  - [ ] Last modified
  - [ ] Actions (View, Edit, Delete, Add to collection)

**Spec coverage**

- [collection_management_spec.rb](spec/features/collection_management_spec.rb)
  - Dashboard collections index page shows the Add New Collection control, count, and a search bar
  - Dashboard collections index page renders the managed collections table with the expected column headers
  - Dashboard collections index page lists a manageable collection with View/Edit/Delete/Add to collection actions
  - Dashboard My Collections filters, search and rows shows each collection's type, last modified date, item count and visibility in its row
  - Dashboard My Collections filters, search and rows narrows the list with the Visibility filter
  - Dashboard My Collections filters, search and rows narrows the list with the Collection Type filter
  - Dashboard My Collections filters, search and rows searches for a specific collection from the search bar

## Dashboard Collection New Page
[Back to TOC](#table-of-contents)

![image57](https://github.com/samvera/hyku/assets/19597776/df577b13-2a60-47e6-9022-5316939664b0)

### As a user:

- [ ] I can see a form to fill out basic information describing my new Collection
  - [ ] Title (required)
  - [ ] Abstract or Summary
- [ ] I can see a button to display Additional fields for which to further describe my collection
- [ ] I can see links to Add another input for most descriptors
  - [ ] I can see links to Remove additional fields
- [ ] I can see a Save button to create my new collection
- [ ] I can see a link to Cancel my new Collection and redirect me back to the dashboard my collections index page

**Spec coverage**

- [collection_management_spec.rb](spec/features/collection_management_spec.rb)
  - creates, edits, and deletes a collection
  - Dashboard collection new page shows the required Title field and an Abstract field
  - Dashboard collection new page shows Additional fields, Add another / Remove controls, Save and Cancel

## Dashboard Collection Edit Page
[Back to TOC](#table-of-contents)

### Description

![image17](https://github.com/samvera/hyku/assets/19597776/ae95babf-2e04-4bfe-9950-552bc3d3b475)

### As a user:

- [ ] I can see a partial to alter / add to my collection’s descriptors
- [ ] I can see a dropdown from which I can select a thumbnail for my collection
- [ ] I can see a button for Additional fields
- [ ] I can see links to Add another input for most descriptors
  - [ ] I can see links to Remove additional fields
- [ ] I can see a button to Save my changes
- [ ] I can see a link to Cancel my edits, redirecting me to the Dashboard Collection’s show page

### Branding (User Collection only)

![image72](https://github.com/samvera/hyku/assets/19597776/75a906fe-4491-4362-b386-463755aad006)

### As a user:

- [ ] I can see a description of how to add optional branding elements to my collection
- [ ] I can see a button to upload a Banner image
  - [ ] I can see a link to Remove an uploaded Banner image
- [ ] I can see a button to upload a Logo image
  - [ ] I can see an input to add a Link URL
  - [ ] I can see an input to add Alt Text
  - [ ] I can see a link to Remove an uploaded Logo image
- [ ] I can see a button to Save my changes
- [ ] I can see a link to Cancel my edits, which redirects me back to the Dashboard Collection show page

### Discovery (User Collection only)

![image6](https://github.com/samvera/hyku/assets/19597776/da92e6dd-e9c7-49cd-a10f-2c415be8ce37)

### As a user:

- [ ] I can see an explanation of the different kinds of Discovery options
- [ ] I can see three radio buttons to set the Visibility of my collection to:
  - [ ] Public
  - [ ] Institution
  - [ ] Private
- [ ] I can see a button to Save my changes
- [ ] I can see a link to Cancel my edits, which redirects me back to the Dashboard Collection show page

### Sharing

![image44](https://github.com/samvera/hyku/assets/19597776/6a5ae284-a7c5-4865-9eaf-c8ee7581da29)

### As a user:

- [ ] I can see a form to share my collection with specific groups and / or users
- [ ] I can see a list of users / groups that I’ve shared my collection with as managers
- [ ] I can see a list of users / groups that I’ve shared my collection with as depositors
- [ ] I can see a list of users / groups that I’ve shared my collection with as viewers
- [ ] I can see Remove buttons to remove individual users / groups from my collection
- [ ] I can see a button to Save my changes
- [ ] I can see a link to Cancel my edits, which redirects me back to the Dashboard Collection show page

**Spec coverage**

- [collection_management_spec.rb](spec/features/collection_management_spec.rb)
  - Dashboard collection edit page tabs Description tab shows the metadata form, Additional fields, Save and Cancel
  - Dashboard collection edit page tabs Description tab adds and removes descriptor inputs with Add another / Remove and saves the result
  - Dashboard collection edit page tabs Description tab offers a dropdown to select the collection thumbnail _(pending/skipped: known gap)_
  - Dashboard collection edit page tabs Cancel on each tab returns to the dashboard collection show page
  - Dashboard collection edit page tabs Branding tab shows banner and logo upload controls
  - Dashboard collection edit page tabs Branding tab with an uploaded banner and logo describes branding and shows the banner and logo with their inputs and Remove buttons
  - Dashboard collection edit page tabs Branding tab with an uploaded banner and logo saves the logo Link URL and Alt Text
  - Dashboard collection edit page tabs Branding tab with an uploaded banner and logo removes the logo with its Remove button
  - Dashboard collection edit page tabs Branding tab with an uploaded banner and logo removes the banner with its Remove button
  - Dashboard collection edit page tabs Discovery tab shows the three visibility radios plus Save and Cancel
  - Dashboard collection edit page tabs Discovery tab explains the discovery options and saves the chosen visibility
  - Dashboard collection edit page tabs Sharing tab shows add group/user forms and Managers/Depositors/Viewers sections
  - Dashboard collection edit page tabs Sharing tab with users shared as depositor and viewer lists each user under Managers, Depositors and Viewers with Remove buttons plus Save and Cancel
  - Dashboard collection edit page tabs Sharing tab with users shared as depositor and viewer removes an individual viewer with its Remove button
  - Dashboard collection edit page tabs Sharing tab with users shared as depositor and viewer shares the collection with a user through the Add user form

## Dashboard Collection Show Page
[Back to TOC](#table-of-contents)

![image29](https://github.com/samvera/hyku/assets/19597776/8a75ff01-dc17-4902-a30b-b687e18163aa)

### As a user:

- [ ] I can see the name of my collection, its visibility, and its collection type
- [ ] I can see buttons to Edit collection, Add to collection, and Delete collection
- [ ] I can see my collection’s representative media
- [ ] I can see a link to the public view of the collection
- [ ] I can see a table of the collection’s metadata
- [ ] I can see a search bar to search subcollections & works within the collection
- [ ] I can see a list of all the Subcollections within the collection
  - [ ] I can see a button to add a collection as a subcollection
  - [ ] I can see a link to create a new collection as a subcollection
- [ ] I can see a link with all the Works within the collection
  - [ ] I can see a button to create a work through the collection
  - [ ] I can see a link to add an existing work to the collection
  - [ ] I can see a button to remove an individual work from the collection

**Spec coverage**

- [collection_show_spec.rb](spec/features/collection_show_spec.rb)
  - shows the collection name, visibility, and collection type
  - shows Edit, Add-to, and Delete collection buttons
  - shows the collection's representative media
  - shows a link to the public view of the collection
  - shows a table of the collection's metadata
  - searches the works within the collection from its search bar
  - lists subcollections with buttons to add and create subcollections
  - lists works with controls to add an existing work and remove a work
  - creating a work through the collection shows a control to create a work through the collection

## Dashboard My Works Index Page
[Back to TOC](#table-of-contents)

![image36](https://github.com/samvera/hyku/assets/19597776/b6cf9d92-c5ae-4927-abae-e6c2b417aec7)

### As a user:

- [ ] I can see a button to Create a batch of works
- [ ] I can see a button to Add a new work
- [ ] I can see the total number of works I own in the repository
- [ ] I can see several dropdowns to sort through my works
- [ ] I can see a search bar to search through my works
- [ ] I can see a list of all the works I own in the repository and some basic information of each:
  - [ ] Title
  - [ ] Date Added
  - [ ] Highlighted
  - [ ] Visibility
  - [ ] Actions (Edit Work, Delete Work, Highlight Work on Profile, Transfer Ownership of Work)

**Spec coverage**

- [dashboard_my_works_spec.rb](spec/features/dashboard_my_works_spec.rb)
  - page header buttons shows "Create batch of works" when batch upload is enabled, alongside "Add New Work"
  - page header buttons hides "Create batch of works" when batch upload is disabled
  - counts and lists only the works the user owns
  - shows Title, Last modified, Highlighted, Visibility and Actions for each work
  - renders the date column from date_modified, not the date the work was added
  - sorting, paging and searching reorders the list from the sort dropdown
  - sorting, paging and searching filters to the matching work from the search bar
  - sorting, paging and searching changes how many works are shown from the per-page dropdown
  - row actions offers Edit, Delete, Highlight and Transfer actions; Edit opens the work form
  - row actions Delete Work removes the work
  - row actions Highlight Work on Profile highlights the work in the list and on the profile

## Dashboard Works New by Batch Page
[Back to TOC](#table-of-contents)

- [ ] In a sidebar:
  - [ ] I can see a list of requirements for creating the new batch work:
    - [ ] Describe your work
    - [ ] Add files
    - [ ] Check deposit agreement
  - [ ] I can set my created works’ visibility
    - [ ] Public
    - [ ] Institution
    - [ ] Embargo
    - [ ] Lease
    - [ ] Private

### Files

![image25](https://github.com/samvera/hyku/assets/19597776/1e598af6-571e-4bcd-8274-b4cdc2836b3b)

### As a user:

- [ ] I can see a button to Add files
- [ ] I can see a button to Add folder
- [ ] Once I’ve added a file, I can set the display label and resource type associated with that file
  - [ ] I can see a button to set all files’ resource type to the selected resource type
- [ ] I can see a button to delete an individual file as to not add it to the work

### Descriptions

![image43](https://github.com/samvera/hyku/assets/19597776/9f0a5aa2-57df-45e9-8b5a-fe5939793f42)

### As a user:

- [ ] I can see three required fields to describe my works:
  - [ ] Creator
  - [ ] Keyword
  - [ ] Rights Statement
- [ ] I can see a button to display Additional fields to describe my works with

### Relationships

![image47](https://github.com/samvera/hyku/assets/19597776/e93b87c5-ebd1-4301-927a-149e40161395)

### As a user:

- [ ] I can see a dropdown to select which Administrative Set to deposit my works into
- [ ] I can see a dropdown to search for existing collections for which to add my work to
- [ ] I can see a list of all selected collections to add my works to
  - [ ] I can see a Remove from collection button

### Sharing

![image30](https://github.com/samvera/hyku/assets/19597776/2ba77b5b-3059-47b6-908b-24667ebe5a96)

### As a user:

- [ ] I can see a form to add groups to have specific access to my created works
  - [ ] Search for existing group to share with
  - [ ] Choose Access level (View/Download, Edit)
  - [ ] Add
- [ ] I can see a form to add individual users to have specific access to my created works
  - [ ] Search for existing user
  - [ ] Choose Access level (View/Download, Edit)
  - [ ] Add
- [ ] I can see a list of all the groups / users I am currently sharing my works with, along with their respective access levels
- [ ] If I add a new group / user, I can see a flash notification informing me that permissions aren’t save until the works are saved

**Spec coverage**

- [batch_work_creation_spec.rb](spec/features/batch_work_creation_spec.rb)
  - shows the batch requirements, visibility options, and all deposit tabs
  - shows per-file display label and resource type controls, sets all resource types, and deletes a file
  - adds a chosen collection to the list with a Remove from collection control
  - shares with a group at a chosen access level and notes that permissions are not yet saved
  - as a depositor permitted to search users (user_reader role) shares with a user at a chosen access level
  - accepts the batch for processing when the form is completed and saved
  - setting the batch visibility applies the chosen visibility to every work created by the batch

## Dashboard Work New Page
[Back to TOC](#table-of-contents)

- [ ] In a sidebar:
  - [ ] I can see a list of requirements for creating the new batch work:
    - [ ] Describe your work
    - [ ] Add files
    - [ ] Check deposit agreement
  - [ ] I can set my created works’ visibility
    - [ ] Public
    - [ ] Institution
    - [ ] Embargo
    - [ ] Lease
    - [ ] Private

### Descriptions

![image60](https://github.com/samvera/hyku/assets/19597776/f0df5b00-37f5-4403-a92c-812a7707adfd)

### As a user:

- [ ] I can see required fields to describe my new work:
  - [ ] Title
  - [ ] Creator
  - [ ] Keyword
  - [ ] Rights Statement
- [ ] I can see a button to display Additional fields
- [ ] Under each input, I can see a link to add an additional input for that descriptor

### Files

![image33](https://github.com/samvera/hyku/assets/19597776/af6dd789-6992-4fe5-b802-9a31911c1f29)

### As a user:

- [ ] I can see a button to Add files
- [ ] I can see a button to Add folder
- [ ] I can see a dropzone to drag-and-drop files to upload
- [ ] I can see the file name and file size of uploaded files
  - [ ] I can see a Delete button next to each file to delete them individually

### Relationships

![image74](https://github.com/samvera/hyku/assets/19597776/dcbedbda-0412-4b51-bba3-e737ecea49d8)

### As a user:

- [ ] I can see a dropdown to select which Administrative Set to deposit my work into
- [ ] I can see a dropdown to search for existing collections for which to add my work to
- [ ] I can see a list of all selected collections to add my works to
  - [ ] I can see a Remove from collection button

### Sharing

![image34](https://github.com/samvera/hyku/assets/19597776/d33be64c-79f3-41fa-b728-71f7b5adc06f)

### As a user:

- [ ] I can see a form to add groups to have specific access to my created work
  - [ ] Search for existing group to share with
  - [ ] Choose Access level (View/Download, Edit)
  - [ ] Add
- [ ] I can see a form to add individual users to have specific access to my created work
  - [ ] Search for existing user
  - [ ] Choose Access level (View/Download, Edit)
  - [ ] Add
- [ ] I can see a list of all the groups / users I am currently sharing my works with, along with their respective access levels
- [ ] If I add a new group / user, I can see a flash notification informing me that permissions aren’t save until the works are saved

**Spec coverage**

- [work_new_form_spec.rb](spec/features/work_new_form_spec.rb)
  - sidebar lists the deposit requirements and offers every visibility option
  - sidebar shows an "Add files" requirement that completes once a file is uploaded, when files are required
  - Descriptions tab shows the required fields and adds another input for a descriptor
  - Files tab uploads a file, lists its name and size, and deletes it
  - Relationships tab offers an Administrative Set dropdown and lists a selected collection with a Remove from collection button
  - Sharing tab shares with a group at a chosen access level and notes that permissions are not yet saved
  - Sharing tab as a depositor permitted to search users (user_reader role) shares with a user at a chosen access level
  - Sharing tab lets a regular depositor find a user in the Sharing tab user search _(pending/skipped: known gap)_
- [work_form_requirements_spec.rb](spec/features/work_form_requirements_spec.rb)
  - shows required metadata, file, relationship, and sharing controls
  - keeps Save disabled until the required metadata and deposit agreement are complete
- [workflow_permissions_spec.rb](spec/features/workflow_permissions_spec.rb)
  - embargo workflow allows setting an embargo during work creation
  - lease workflow allows setting a lease during work creation
  - relationships tab shows the relationships tab on the new work form

## Dashboard Work Edit Page
[Back to TOC](#table-of-contents)

### Descriptions

![image50](https://github.com/samvera/hyku/assets/19597776/385552b8-3e8f-4797-9826-0b60cec3c0a3)

### As a user:

- [ ] I can see the required fields already filled in:
  - [ ] Title
  - [ ] Creator
  - [ ] Keyword
  - [ ] Rights Statement
- [ ] I can see blank input fields under the filled input fields with an option to remove them
- [ ] I can see a button to add Additional Fields

### Files

![image9](https://github.com/samvera/hyku/assets/19597776/ced7da5d-642f-455b-8511-443f009cd0cc)

### As a user:

- [ ] I can see a button to Add files
- [ ] I can see a button to Add folder
- [ ] I can see a dropzone to drag-and-drop files to upload
- [ ] I can see the file name and file size of uploaded files
  - [ ] I can see a Delete button next to each file to delete them individually

### Relationships

![image46](https://github.com/samvera/hyku/assets/19597776/c759f3ae-8760-4c36-b689-eebd9ef91d55)

### As a user:

- [ ] I can see a dropdown to select which Administrative Set to deposit my work into
- [ ] I can see a dropdown to search for existing collections for which to add my work to
- [ ] I can see a list of all selected collections to add my works to
  - [ ] I can see a Remove from collection button
- [ ] I can see a dropdown to search for child works
- [ ] I can see a button to Deposit a new work as a child of this work
- [ ] I can see a list of all existing child works

### Sharing

![image78](https://github.com/samvera/hyku/assets/19597776/159b2ef8-3195-40d8-ad36-31c745bcd7ac)

### As a user:

- [ ] I can see a form to add groups to have specific access to my created work
  - [ ] Search for existing group to share with
  - [ ] Choose Access level (View/Download, Edit)
  - [ ] Add
- [ ] I can see a form to add individual users to have specific access to my created work
  - [ ] Search for existing user
  - [ ] Choose Access level (View/Download, Edit)
  - [ ] Add
- [ ] I can see a list of all the groups / users I am currently sharing my works with, along with their respective access levels
- [ ] If I add a new group / user, I can see a flash notification informing me that permissions aren’t save until the works are saved

**Spec coverage**

- [work_form_requirements_spec.rb](spec/features/work_form_requirements_spec.rb)
  - the work edit page tabs Descriptions tab shows the required fields pre-filled, a removable blank input, and Additional fields
  - the work edit page tabs Files tab shows the add-files controls and dropzone that render on load
  - the work edit page tabs Files tab uploads a file, lists its name and size, and deletes it
  - the work edit page tabs Relationships tab shows admin set, collection and child-work pickers plus the child works list
  - the work edit page tabs Sharing tab shows the group and user add forms with access levels and the current shares
  - the work edit page tabs Sharing tab adds a group share, notes it is unsaved, and persists it when the work is saved
  - the work edit page tabs Sharing tab as a depositor permitted to search users (user_reader role) adds a user share with its access level
  - the edit page for an existing work (Dashboard Work Edit Page) when the work is in a collection lists the collection with a Remove control
- [workflow_permissions_spec.rb](spec/features/workflow_permissions_spec.rb)
  - sharing workflow offers existing groups to share with on the Sharing tab

## Review Submissions Page
[Back to TOC](#table-of-contents)

### Under Review

![image22](https://github.com/samvera/hyku/assets/19597776/8216b4bd-00dd-4840-9ac6-5a3367398c4c)

### As an admin/approving user:

- [ ] I can see a list of deposited works that require review before being published
- [ ] For each work pending review, I can see the:
  - [ ] Work
  - [ ] Depositor
  - [ ] Submission Date
  - [ ] Status

### Published

![image7](https://github.com/samvera/hyku/assets/19597776/789c1883-2073-4296-81ea-9fb18ce994d3)

### As an admin/approving user:

- [ ] I can see a list of deposited works that are published
- [ ] For each published work, I can see the:
  - [ ] Work
  - [ ] Depositor
  - [ ] Submission Date
  - [ ] Status

**Spec coverage**

- [review_submissions_spec.rb](spec/features/review_submissions_spec.rb)
  - lists a pending submission with its work, depositor, submission date and status
  - approves a pending submission and changes its workflow state
  - requests changes on a pending submission and changes its workflow state
  - lists only deposited works, with their depositor, date and status, under the Published tab

## Manage Users Page
[Back to TOC](#table-of-contents)

![image12](https://github.com/samvera/hyku/assets/19597776/d388bb17-3cba-46be-a6fb-b6500cbfc7e2)

### As an admin:

- [ ] I can see a form to add or invite a user via email
- [ ] I can see the total number of users in my repository
- [ ] I can see a list of all users in my repository, including their:
  - [ ] Username
  - [ ] Roles
  - [ ] Last Access
  - [ ] Status
- [ ] I can see a delete button next to each user to remove them from this repository

**Spec coverage**

- [manage_users_and_groups_spec.rb](spec/features/manage_users_and_groups_spec.rb)
  - Manage Users Page shows the exact total number of users in the repository
  - Manage Users Page lists each user with their username, roles, last access, and status
  - Manage Users Page adds/invites a user via email with a role, listed as Pending
  - Manage Users Page removes a user from the repository with the Delete button next to them

## Manage Groups Index Page
[Back to TOC](#table-of-contents)

![image76](https://github.com/samvera/hyku/assets/19597776/f0f7cd59-8406-4ba3-943f-3e9b0ad53091)

### As an admin:

- [ ] I can see the total number of groups in my repository
- [ ] I can see a button to Create New Group
- [ ] I can see a search box to search for specific groups
- [ ] I can see a list of all groups in my repository, along with some basic information:
  - [ ] Name
  - [ ] Users (count)
  - [ ] Date Created
- [ ] I can see a button next to each group to Edit group and users

**Spec coverage**

- [manage_users_and_groups_spec.rb](spec/features/manage_users_and_groups_spec.rb)
  - Manage Groups Index Page shows the total number of groups
  - Manage Groups Index Page lists each group with its name, user count, and creation date
  - Manage Groups Index Page searches for specific groups
  - Manage Groups Index Page opens the new group form with Create New Group
  - Manage Groups Index Page opens a group for editing with Edit group & users

## Manage Groups New Page
[Back to TOC](#table-of-contents)

![image66](https://github.com/samvera/hyku/assets/19597776/a9aa8c2d-5c62-4671-b9a7-06cabea473ea)

### As an admin:

- [ ] I can see a link to return to the Manage Groups index page
- [ ] I can see a form to enter information about my new group:
  - [ ] Name (Required)
  - [ ] Description
- [ ] I can see a Users and Remove tab
  - [ ] Both tabs are unavailable for new groups and are likewise disabled
- [ ] I can see a Save button to submit my form and create a new group
- [ ] I can see a link to Cancel my new group, which redirects me back to the Manage Groups index page

**Spec coverage**

- [manage_users_and_groups_spec.rb](spec/features/manage_users_and_groups_spec.rb)
  - Manage Groups New Page returns to the Manage Groups index from the back link
  - Manage Groups New Page has a required Name and a Description, with the other tabs disabled
  - Manage Groups New Page creates a new group with Save
  - Manage Groups New Page cancels the new group and returns to the Manage Groups index

## Manage Groups Edit Page
[Back to TOC](#table-of-contents)

### Description

![image64](https://github.com/samvera/hyku/assets/19597776/87db3a2a-f974-46f3-befa-0a2fc7204183)

### As an admin:

- [ ] I can see a link to return to the Manage Groups index page
- [ ] I can see a form with the fields already filled:
  - [ ] Name (Required)
  - [ ] Description
- [ ] I can see a Save Changes button to submit my form to edit the group
- [ ] I can see a link to Cancel my edits, which redirects me back to the Manage Groups index page

### Users

![image31](https://github.com/samvera/hyku/assets/19597776/b4b70882-daaf-421d-bba2-7f3b9f4142b8)

### As an admin:

- [ ] I can see a link to return to the Manage Groups index page
- [ ] I can see an input to search for existing users to add to the group
- [ ] I can see a list of all current group members, including their:
  - [ ] Name
  - [ ] Username
  - [ ] Joined
  - [ ] Last access
- [ ] I can see a Remove button next to each user to remove them from the group
- [ ] I can see a search bar to search through users within the group

### Remove

![image67](https://github.com/samvera/hyku/assets/19597776/410d5143-d0e5-43e2-8f7e-36149198b564)

### As an admin:

- [ ] I can see a link to return to the Manage Groups index page
- [ ] I can see a button to remove the group from the repository, effectively deleting it
- [ ] I can see a warning explaining the irreversible consequences of this action

**Spec coverage**

- [manage_users_and_groups_spec.rb](spec/features/manage_users_and_groups_spec.rb)
  - Manage Groups Edit Page returns to the Manage Groups index from the back link on the Description, Users, and Remove tabs
  - Manage Groups Edit Page Description tab shows the filled-in form and saves changes
  - Manage Groups Edit Page Description tab cancels the edits and returns to the Manage Groups index
  - Manage Groups Edit Page Users tab lists current members with their name, username, joined date, and last access
  - Manage Groups Edit Page Users tab removes a member from the group with the Remove button next to them
  - Manage Groups Edit Page Users tab searches through the users within the group
  - Manage Groups Edit Page Users tab searches for an existing user and adds them to the group
  - Manage Groups Edit Page Remove tab warns about the irreversible removal and deletes the group

## Manage Embargoes Index Page
[Back to TOC](#table-of-contents)

### All Active Embargoes

![image14](https://github.com/samvera/hyku/assets/19597776/eb47f793-561f-4523-9860-8b86ff7e399d)

### As an admin:

- [ ] I can see all items currently under embargo (works and files)
  - [ ] Type of Item
  - [ ] Title
  - [ ] Current Visibility
  - [ ] Embargo Release Date
  - [ ] Visibility will Change to

### Expired Active Embargoes

![image80](https://github.com/samvera/hyku/assets/19597776/c33db3ef-74a8-45aa-8248-e996dfe9f317)

### As an admin:

- [ ] I can see a list of all embargoes that have expired, including their:
  - [ ] Type of Item
  - [ ] Title
  - [ ] Current Visibility
  - [ ] Embargo Release Date
  - [ ] Visibility will Change to

### Deactivated Embargoes

![image51](https://github.com/samvera/hyku/assets/19597776/05261979-da64-4746-b8b9-317688fa44c2)

### As an admin:

- [ ] I can see a list of all deactivated embargoes, along with their current visibility

**Spec coverage**

- [manage_embargoes_and_leases_spec.rb](spec/features/manage_embargoes_and_leases_spec.rb)
  - Manage Embargoes index page lists every enforced embargo (works and file sets) under All Active Embargoes
  - Manage Embargoes index page lists only past-due, still-enforced embargoes under Expired Active Embargoes
  - Manage Embargoes index page releases selected expired embargoes with "Deactivate Embargoes for Selected"
  - Manage Embargoes index page records the batch-released embargo in its history and under Deactivated Embargoes _(pending/skipped: known gap)_
  - Manage Embargoes index page lists deactivated embargoes with their current visibility and history

## Manage Embargoes Edit Page
[Back to TOC](#table-of-contents)

![image61](https://github.com/samvera/hyku/assets/19597776/2771169a-f7e7-48f2-a24c-719d8d89cc7b)

### As an admin:

- [ ] I can see a form to edit the attributes of the active embargo
- [ ] I can see a button to Update the Embargo with my changes
- [ ] I can see a button to Deactivate Embargo
- [ ] I can see a button to Cancel and return to the Manage Embargoes index page
- [ ] I can see a button to return to the work’s / file’s individual edit page
- [ ] I can see a list of this item’s past embargoes

**Spec coverage**

- [manage_embargoes_and_leases_spec.rb](spec/features/manage_embargoes_and_leases_spec.rb)
  - Manage Embargoes edit page shows the current embargo in an editable form and Update changes it
  - Manage Embargoes edit page Deactivate Embargo releases the embargo and records it under Past Embargoes
  - Manage Embargoes edit page Cancel returns to Manage Embargoes and the return link opens the work edit page
  - Manage Embargoes edit page links a file set embargo back to the file set edit page

## Manage Embargoes Deactivate Page
[Back to TOC](#table-of-contents)

![image2](https://github.com/samvera/hyku/assets/19597776/177c5dd5-dffb-4e57-be98-30e017be239c)

### As an admin, upon deactivation of an active embargo:

- [ ] I can see a button to also deactivate all the active embargoes on files within the work
- [ ] I can see a button to leave the active embargoes on the files within the work

**Spec coverage**

- [manage_embargoes_and_leases_spec.rb](spec/features/manage_embargoes_and_leases_spec.rb)
  - Manage Embargoes deactivating the embargo of a work with file sets asks whether to apply the change to the files, offering both choices
  - Manage Embargoes deactivating the embargo of a work with file sets names the work by its title on the confirmation page _(pending/skipped: known gap)_
  - Manage Embargoes deactivating the embargo of a work with file sets "Yes please." copies the released visibility to the files, lifting their embargo
  - Manage Embargoes deactivating the embargo of a work with file sets "No. I'll update it manually." leaves the file embargoes in place

## Manage Leases Index Page
[Back to TOC](#table-of-contents)

### All Active Leases

![image19](https://github.com/samvera/hyku/assets/19597776/a31fbaf2-d837-4117-9ba5-68470973d77b)

### As an admin:

- [ ] I can see all items with active leases (works and files)
  - [ ] Type of Item
  - [ ] Title
  - [ ] Current Visibility
  - [ ] Lease Release Date
  - [ ] Visibility will Change to

### Expired Active Leases

![image27](https://github.com/samvera/hyku/assets/19597776/b2cd1a11-4cd8-4352-aad5-a6f2b0af7f1a)

### As an admin:

- [ ] I can see a list of all leases that have expired, including their:
  - [ ] Type of Item
  - [ ] Title
  - [ ] Current Visibility
  - [ ] Lease Release Date
  - [ ] Visibility will Change to

### Deactivated Leases

![image70](https://github.com/samvera/hyku/assets/19597776/bbfb6174-c0b0-4931-95c8-5ea5f88ec89d)

### As an admin:

- [ ] I can see a list of all deactivated leases, along with their current visibility

**Spec coverage**

- [manage_embargoes_and_leases_spec.rb](spec/features/manage_embargoes_and_leases_spec.rb)
  - Manage Leases index page lists every enforced lease (works and file sets) under All Active Leases
  - Manage Leases index page lists only past-due, still-enforced leases under Expired Active Leases
  - Manage Leases index page releases selected expired leases with "Deactivate Leases for Selected"
  - Manage Leases index page records the batch-released lease in its history and under Deactivated Leases _(pending/skipped: known gap)_
  - Manage Leases index page lists deactivated leases with their current visibility and history

## Manage Leases Edit Page
[Back to TOC](#table-of-contents)

![image28](https://github.com/samvera/hyku/assets/19597776/1918467a-cd6a-47a6-84de-b6ddbf43c83c)

### As an admin:

- [ ] I can see a form to edit the attributes of the active lease
- [ ] I can see a button to Update the Lease with my changes
- [ ] I can see a button to Deactivate Lease
- [ ] I can see a button to Cancel and return to the Manage Leases index page
- [ ] I can see a button to return to the work’s / file’s individual edit page
- [ ] I can see a list of this item’s past leases

**Spec coverage**

- [manage_embargoes_and_leases_spec.rb](spec/features/manage_embargoes_and_leases_spec.rb)
  - Manage Leases edit page shows the current lease in an editable form and Update changes it
  - Manage Leases edit page Deactivate Lease releases the lease and records it under Past Leases
  - Manage Leases edit page Cancel returns to Manage Leases and the return link opens the work edit page
  - Manage Leases edit page links a file set lease back to the file set edit page

## Manage Leases Deactivate Page
[Back to TOC](#table-of-contents)

![image49](https://github.com/samvera/hyku/assets/19597776/cfe78196-ba15-44ea-a19d-e5893c92c08e)

### As an admin, upon deactivation of an active lease:

- [ ] I can see a button to also deactivate all the active leases on files within the work
- [ ] I can see a button to leave the active leases on the files within the work

**Spec coverage**

- [manage_embargoes_and_leases_spec.rb](spec/features/manage_embargoes_and_leases_spec.rb)
  - Manage Leases deactivating the lease of a work with file sets asks whether to apply the change to the files, offering both choices
  - Manage Leases deactivating the lease of a work with file sets "Yes please." copies the released visibility to the files, lifting their lease
  - Manage Leases deactivating the lease of a work with file sets "No. I'll update it manually." leaves the file leases in place

## Settings → Labels Page
[Back to TOC](#table-of-contents)

![image20](https://github.com/samvera/hyku/assets/19597776/c9e7c10d-b0dc-4a79-bc4c-134e500c52dd)

### As an admin:

- [ ] I can see a form to General Repository Labels for my site, including:
  - [ ] Application name
  - [ ] Institution name
  - [ ] Full institution name
- [ ] I can see a button to Save my changes

**Spec coverage**

- [admin_settings_spec.rb](spec/features/admin_settings_spec.rb)
  - Labels saves the application name, institution name, and full institution name

## Settings → Appearance Page
[Back to TOC](#table-of-contents)

### Logo / Banner Image

![image41](https://github.com/samvera/hyku/assets/19597776/4ef27787-96ea-46d9-bc71-54e64afe13e3)

### As an admin:

- [ ] I can see a file upload input to add a logo to my site
- [ ] I can see a file upload input to add a banner to my site
- [ ] I can see a Save changes button

### Default Images

![image71](https://github.com/samvera/hyku/assets/19597776/dee61f1e-53b8-4bf7-811f-23cf3d8bf86b)

### As an admin:

- [ ] I can see a file upload input to set a default collection image
- [ ] I can see a file upload input to set a default work image
- [ ] I can see a Save changes button

### Colors

![image42](https://github.com/samvera/hyku/assets/19597776/f7042081-1447-4849-857a-13288556a4c9)

### As an admin:

- [ ] I can see several key elements throughout the website that each have a color picker input to adjust their color globally throughout the repository
- [ ] Beside each color picker, there is a Restore Default button that restores the color to its default value
- [ ] I can see a Restore All Defaults button that restores all of the color pickers to their default values
- [ ] I can see a Save changes button

### Fonts

![image45](https://github.com/samvera/hyku/assets/19597776/e50447d3-c024-449c-8403-ba5b4552cf38)

### As an admin:

- [ ] I can see a dropdown menu to select a font for body elements site-wide
  - [ ] Below this, there is a Restore Default button that restores the font to its default value
- [ ] I can see a dropdown menu to select a font for headline elements site-wide
  - [ ] Below this, there is a Restore Default button that restores the font to its default value
- [ ] I can see a Restore All Defaults button that restores all of the fonts pickers to their default values
- [ ] I can see a Save changes button

### Custom CSS

![image8](https://github.com/samvera/hyku/assets/19597776/3b7a1031-ae30-4d30-9927-617464a69cbd)

### As an admin:

- [ ] I can see a textarea to enter custom CSS that will can apply throughout the repository
- [ ] I can see a Save changes button

**Spec coverage**

- [admin_settings_spec.rb](spec/features/admin_settings_spec.rb)
  - Appearance uploads a logo and a banner image with Save changes
  - Appearance uploads default collection and work images with Save changes
  - Appearance saves a changed color with Save changes (Apply Changes) and applies it to the site
  - Appearance saves the body and headline fonts with Save changes and applies them to the site
  - Appearance imports a changed headline font even when the body font stays the default _(pending/skipped: known gap)_
  - Appearance saves custom CSS with Save changes and serves it on the site
  - Appearance with JavaScript has a color picker and a Restore Default button per element, plus Restore All Defaults
  - Appearance with JavaScript has body and headline font dropdowns with Restore Default buttons, plus Restore All Defaults

## Settings → Collection Types Index Page
[Back to TOC](#table-of-contents)

![image79](https://github.com/samvera/hyku/assets/19597776/c93ba62b-d4ce-4fb5-957c-9d71b508cb4b)

### As a admin:

- [ ] I can see the total number of collection types I have in this repository
- [ ] I can see a button to create a new collection type
- [ ] I can see a link to display more information about collection types
- [ ] I can see a list of all the current collection types within my repository
  - [ ] I can see a button next to each collection type to Edit it
  - [ ] I can see a button next to each custom, non-default collection type to Delete it

**Spec coverage**

- [collection_management_spec.rb](spec/features/collection_management_spec.rb)
  - Settings -> Collection Types (admin) index page shows the count, Create new collection type button, and edit/delete controls
  - Settings -> Collection Types (admin) index page expands more information about collection types
  - Settings -> Collection Types (admin) index page opens a collection type for editing from its Edit button

## Settings → Collection Types New Page
[Back to TOC](#table-of-contents)

![image58](https://github.com/samvera/hyku/assets/19597776/abbc5b8c-1af7-495e-a16c-72275c2c374f)

### As an admin:

- [ ] I can see a form to create a new collection types, describing it with:
  - [ ] Type name (required)
  - [ ] Type description
- [ ] I can see a Save button to create my collection type
- [ ] I can see a link to Cancel the creation of a new collection type, redirecting me back to the collection types index page

**Spec coverage**

- [collection_management_spec.rb](spec/features/collection_management_spec.rb)
  - Settings -> Collection Types (admin) new page shows required Type name, Type description, Save and Cancel
  - Settings -> Collection Types (admin) new page returns to the collection types index from Cancel

## Settings → Collection Types Edit Page
[Back to TOC](#table-of-contents)

### Description

![image54](https://github.com/samvera/hyku/assets/19597776/882e65cb-95cb-457b-8d07-72c29a15de4e)

### As an admin:

- [ ] I can see a form to edit a collection type, describing it with the attributes filled:
  - [ ] Type name (required)
  - [ ] Type description
- [ ] I can see a Save Changes button to edit my collection type
- [ ] I can see a link to Cancel the editing of a new collection type, redirecting me back to the collection types index page

### Settings

![image56](https://github.com/samvera/hyku/assets/19597776/ecf09ff6-878b-40f7-bb25-6621fcb10011)

### As an admin:

- [ ] I can see several checkboxes describing different settings related to the collection type
  - [ ] All the checkboxes are disabled, as they can only be changed upon creation of the collection type
- [ ] I can see a Save button to create my collection type
- [ ] I can see a link to Cancel the creation of a new collection type, redirecting me back to the collection types index page

### Participants

![image53](https://github.com/samvera/hyku/assets/19597776/9145c6c7-3a03-4a7a-979e-d23f3e47ce3a)

### As an admin:

- [ ] I can see a form to add groups to have specific access to the collection type
- [ ] I can see a form to add users to have specific access to the collection type
- [ ] I can see a list of Managers of this collection type
  - [ ] I can remove individual managers from this collection type
- [ ] I can see a list of Creators of this collection type
  - [ ] I can remove individual creators from this collection type
- [ ] I can see a Save changes button
- [ ] I can see a link to Cancel the edits on the collection type, redirecting me back to the collection types index page

### Badge Color

![image69](https://github.com/samvera/hyku/assets/19597776/6e099899-65c0-4cab-a86b-1ec62c2f511e)

### As an admin:

- [ ] I can see a color picker input to select a badge color for the collection type
- [ ] I can see a button to Save my changes
- [ ] I can see a link to Cancel my changes, redirecting me back to the Collection Types Index page

**Spec coverage**

- [collection_management_spec.rb](spec/features/collection_management_spec.rb)
  - Settings -> Collection Types (admin) edit page exposes Description, Settings, Participants and Badge Color tabs
  - Settings -> Collection Types (admin) edit page shows the Description form filled with the type name and description
  - Settings -> Collection Types (admin) edit page shows disabled admin-set-only checkboxes on the Settings tab
  - Settings -> Collection Types (admin) edit page shows the participants add-group/add-user forms and Manager/Creator lists
  - Settings -> Collection Types (admin) edit page adds a user as a manager with the Add user form and removes them again
  - Settings -> Collection Types (admin) edit page removes an individual creator
  - Settings -> Collection Types (admin) edit page shows a color picker on the Badge Color tab plus Save and Cancel

## Settings → Pages Page
[Back to TOC](#table-of-contents)

![image63](https://github.com/samvera/hyku/assets/19597776/d7442aa4-5bfe-41c4-bbf5-12b87393f687)

### As an admin:

- [ ] I can see a WYSIWYG to change the content for each of the site’s static pages:
  - [ ] About Page
  - [ ] Help Page
  - [ ] Deposit Agreement
  - [ ] Terms of Use
- [ ] I can see a button to Save my changes
- [ ] I can see a button to Cancel my changes

**Spec coverage**

- [admin_settings_spec.rb](spec/features/admin_settings_spec.rb)
  - Pages saves the content of each static page and shows it on the public page
  - Pages cancels changes and returns to the Pages form _(pending/skipped: known gap)_
  - Pages edits each page in a WYSIWYG editor

## Settings → Content Block
[Back to TOC](#table-of-contents)

![image37](https://github.com/samvera/hyku/assets/19597776/b7344127-b404-477d-94e0-431d59ec2e64)

### As an admin:

- [ ] I can see a WYSIWYG to change the content for each of the site’s content blocks:
  - [ ] Announcement Text
  - [ ] Marketing Text
  - [ ] Home Page Text
  - [ ] Featured Researcher
- [ ] I can see a button to Save my changes
- [ ] I can see a button to Cancel my changes

**Spec coverage**

- [admin_settings_spec.rb](spec/features/admin_settings_spec.rb)
  - Content Block saves each content block and shows it on the homepage
  - Content Block cancels changes and returns to the Content Blocks form _(pending/skipped: known gap)_
  - Content Block shows a WYSIWYG editor to change the content for each of the site's content blocks

## Settings → Features Page
[Back to TOC](#table-of-contents)

![image52](https://github.com/samvera/hyku/assets/19597776/97b0a1fe-4457-4f25-b85f-bc619a1618d2)

### As an admin:

- [ ] I can see a list of different site configuration features to alter how the site functions
  - [ ] Each feature has two options: On and Off

**Spec coverage**

- [admin_settings_spec.rb](spec/features/admin_settings_spec.rb)
  - Features lists each feature with On and Off controls
  - Features turns a feature off and on, changing the site behavior

## Workflow Roles Page
[Back to TOC](#table-of-contents)

![image59](https://github.com/samvera/hyku/assets/19597776/27323704-0f9f-48b9-b2dc-76d3ce0d43ee)

### As an admin:

- [ ] I can see a form to select an existing user and assign them a specific workflow role
- [ ] I can see a list of all users within a repository and their corresponding workflow roles
  - [ ] I can see a search bar to search for specific users or roles

**Spec coverage**

- [workflow_permissions_spec.rb](spec/features/workflow_permissions_spec.rb)
  - Workflow Roles Page assigns an existing user a specific workflow role with the form
  - Workflow Roles Page lists all users in the repository with their workflow roles
  - Workflow Roles Page filters the user roles list with its search bar by user or by role
- [dashboard_and_admin_dashboard_spec.rb](spec/features/dashboard_and_admin_dashboard_spec.rb)
  - shows Workflow Roles under Configuration only when that menu item is enabled

