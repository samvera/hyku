# Groups with Roles

## Table of Contents
  * [Using the Feature](#using-the-feature)
    * [Example use cases](#example-use-cases)
      * [Deposit and edit access to a single Collection (and Admin Set)](#deposit-and-edit-access-to-a-single-collection-and-admin-set)
    * [Ability Matrix](#ability-matrix)
    * [Further documentation](#further-documentation)
  * [Defining Roles, Users, and Groups](#defining-roles-users-and-groups)
  * [Setup an Existing Application to use Groups with Roles](#setup-an-existing-application-to-use-groups-with-roles)
    * [Migrate existing data](#migrate-existing-data)
    * [Update Solr Configset](#update-solr-configset)
  * [Role Set Creation Guidelines](#role-set-creation-guidelines)
    * [Search Permissions Notes](#search-permissions-notes)

---

## Using the feature

### Example use cases

#### Deposit and edit access to a single Collection (and Admin Set)

> Person A emails the tenant manager and says, "I work for Institution Z, and I need to be able to deposit works for my institution and edit my colleagues' work." The tenant manager adds Person A to a group called Institution Z Managers. Members of this group can deposit works without approval into the collection called Institution Z Publications. In the rest of the tenant, outside the Institution Z Publications collection, Person A has the same permissions as any other registered user.

_To configure a tenant to fulfill the above scenario, follow these steps (requires admin privileges):_ 

1. Create the Admin Set that works will be deposited into

> "I need to be able to deposit works for my institution"

Every work in Hyku is deposited into an Admin Set (not to be confused with a Collection). To create our admin set, navigate to Dashboard > Collections. Click the `Add New Collection` button at the top right. Select `Admin Set` in the "Select type of collection" pop up. Click `Create collection`. Give the Admin Set a title (in this case, we'll use "Institution Z Admin Set"). Click `Save`. 

1a. Configuring approval requirement

> ...can deposit works **without approval**...

The Admin Set needs to be configured not to require an approval step for works deposited into it: 

Navigate to Dashboard > Collections. Edit the `Institution Z Admin Set`. Under the Workflow tab, select `Default workflow` (this is Hyku's non-mediated deposit option). Click `Save changes`.

2. Create the Institution Z Publications Collection

> Members of this group can deposit works... into the collection called Institution Z Publications

Navigate to Dashboard > Collections. Click the `Add New Collection` button at the top right. Select `User Collection` in the "Select type of collection" pop up. Click `Create collection`. Give the Collection the title "Institution Z Publications". Click `Save`.

3. Create the Group

> ...a group called Institution Z Managers

Navigate to Dashboard > Manage Groups. Click `Create New Group` in the top right. Give the group the name of "Institution Z Managers". Click `Save`. 

4. Grant the Group the appropriate access 

4a. Work deposit and edit access 

> I need to be able to deposit works for my institution and edit my colleagues' work.

Navigate to Dashboard > Collections. Edit the `Institution Z Admin Set`. Under the `Participants` tab, grant the Institution Z Managers group the "Manager" role for the admin set. Verify the group appears in the `Managers` table under the `Current Participants` section. 

4b. Access to Institution Z Publications collection 

> Members of this group can deposit... into the collection called Institution Z Publications.

Navigate to Dashboard > Collections. Edit the `Institution Z Publications` collection. Under the `Sharing` tab, grant the Institution Z Managers group the "Depositor" role for the collection. Verify the group appears in the `Depositors` table under the `Currently Shared With` section.

4c. Do NOT give the Institution Z Managers group any Roles

> In the rest of the tenant, outside the Institution Z Publications collection, Person A has the same permissions as any other registered user.

Roles granted to a group (i.e. under the `Roles` tab when editing a group) grant permissions across the entire tenant. For example, if a group is given the the `Work Editor` role, all members in that group would be able to edit any work and deposit works into any Admin Set.

5. Add Person A to the Institution Z Managers group

Navigate to Dashboard > Manage Groups. Edit the "Institution Z Managers" group. Under the `Users` tab, search for Person A using their email address (or username) and add them to the group by clicking on the search result. 

### Ability Matrix

_This table currently does not reflect all possible permission configurations_

| Action | Source of permission | Where to configure |
| --- | --- | --- |
| Deposit works into a specific Admin Set | Grant group/user `Manager` Workflow Role | Admin Set form's "Participants" tab |
| Edit all works in a specific Admin Set | Grant group/user `Manager` Workflow Role | Admin Set form's "Participants" tab |
| Deposit without approval | Admin Set's configured Workflow | Admin Set form's "Workflow" tab |
| Deposit works into specific Collection | Grant group/user `Depositor` Collection role | Collection form's "Sharing" tab |
| Deposit works into **any** Admin Set | Grant group/user `Work Depositor` Role | Group form's "Roles" tab |

### Further documentation
[Managing Users, Groups and Permissions](https://docs.google.com/document/d/1dQta2JaT0rLPibl9XZNVt5VLskEWL9Ojym8EFKGdHYE/edit#heading=h.rrrlo1kmlxki)

## Defining Roles, Users, and Groups

Permissions for users in Hyku are complex and configurable. This guide will outline the default, recommended way of utilizing these features, but other customizations are possible.

First, it is worthwhile to define some basic concepts:

- Role: a specific permission over some aspect of repository management. Hyku includes the roles listed below. Each role inherits the abilities of the roles below it:
  - Admin	Grants: unrestricted access to this tenant
  - Collection Editor: Can create, read, and edit any Collection in this tenant	
  - Collection Manager: Can create, read, edit, and destroy any Collection in this tenant	
  - Collection Reader: Can read any Collection in this tenant	
  - User Manager: Can read, edit, invite, and remove any User in this tenant	
  - User Reader: Can read any User in this tenant	
  - Work Editor: Can create, read, edit, and approve any Work in this tenant, as well as move Works between Admin Sets and manage Embargoes and Leases
  - Work Depositor: Can deposit Works into any Admin Set in this tenant. Can read, edit, and manage Embargoes / Leases for Works belonging to them	

- Workflow role: a subset of roles that pertains to the depositing, approving, or managing works within a specific admin set. Roles granted across all repositories are automatically granted different workflow roles over all admin sets:
  - Managing: can add works, edit admin set configuration, and approve works submitted through a mediated deposit workflow
    - Those with Admin and Collection Manager roles are automatically admin set managers
  - Approving: can approve works submitted through a mediated deposit workflow
    - Those with Collection Editor and Work Editor are automatically able to approve in admin sets
  - Depositing: can add works to the admin set, whether a mediated or default workflow
    - Those with the Depositor role can deposit to any admin set

- Group: a predefined set of roles used to create desired classes of users. Groups are how we recommend you control your user permissions. Hyku comes with the following default groups:
  - Repository Administrators: Users in this group are considered admins for this tenant and have unrestricted access.
    - Roles: Admin.
  - Editors: Users in this group are considered admins for this tenant and have unrestricted access.
    - Roles: Work Editor, Collection Editor, User Reader.
  - Depositors: Users in this group are allowed to deposit Works into any Admin Set in this tenant.
    - Roles: Work Depositor.
  - Registered Users: Contains all users who have signed up in this tenant.
    - No roles.

- User: individual accounts in Hyku that are assigned specific roles or to a group that has a predefined combination of roles.

## Setup an Existing Application to use Groups with Roles

### Migrate existing data

These rake tasks will create data across all tenants necessary to setup Groups with Roles. **Run them in the order listed below.**

Prerequisites:
- All Collections must have CollectionTypes _and_ PermissionTemplates (see the **Collection Migration** section in the [Hyrax 2.1 Release Notes](https://github.com/samvera/hyrax/releases/tag/v2.1.0))

```bash
rake hyku:roles:create_default_roles_and_groups
rake hyku:update_hyrax_group_names
rake hyku:roles:create_collection_accesses
rake hyku:roles:create_admin_set_accesses
rake hyku:roles:create_collection_type_participants
rake hyku:roles:create_admin_group_memberships
rake hyku:roles:grant_workflow_roles
rake hyku:roles:destroy_registered_group_collection_type_participants # optional
```

<sup>\*</sup> The `hyku:roles:destroy_registered_group_collection_type_participants` task is technically optional. However, without it, collection readers will be allowed to create Collections.

Default `Role`s and `Hyrax::Group`s are seeded into an account (tenant) at creation time (see [CreateAccount#create_defaults](app/services/create_account.rb)), so these only need to be run once.

### Update Solr Configset

For search permissions to work properly, a new Solr configset (with a unique name) will need to be uploaded.

_In this example, our new configset's name will be `hyku-groups-with-roles`. You can rename this to what makes the most sense for your use case._

```bash
# bash
export SOLR_CONFIGSET_NAME_NEW=hyku-groups-with-roles
SOLR_CONFIGSET_NAME=$SOLR_CONFIGSET_NAME_NEW solrcloud-upload-configset.sh /app/samvera/hyrax-webapp/solr/conf
```

Next, each `Account`'s solr config needs to be modified with the new name:

```ruby
# in the rails console
Account.find_each do |a|
  result = %x{curl -X POST "#{ENV['SOLR_URL']}admin/collections?action=MODIFYCOLLECTION&collection=#{a.solr_endpoint.collection}&collection.configName=#{ENV['SOLR_CONFIGSET_NAME_NEW']}"}
  raise "#{a.name} did not update" unless result.match('success')
end
```

In the Solr Dashboard, you can confirm the new configset is being used by selecting a Collection in the left sidebar, looking at its Overview page, and finding the Config Name. This should now display the value of `SOLR_CONFIGSET_NAME_NEW`.

## Role Set Creation Guidelines
1. Add role names to the [RolesService::DEFAULT_ROLES](app/services/roles_service.rb) constant
2. Find related ability concern in Hyrax (if applicable)
  - Look in `app/models/concerns/hyrax/ability/` (local repo first, then Hyrax's repo)
  - E.g. ability concern for Collections is `app/models/concerns/hyrax/ability/collection_ability.rb`
  - If a concern matching the record type exists in Hyrax, but no the local repo, copy the file into the local repo
    - Be sure to add override comments (use the `OVERRIDE:` prefix)
  - If no concern matching the record type exists, create one.
    - E.g. if creating an ablility concern for the `User` model, create `app/models/concerns/hyrax/ability/user_ability.rb`
3. Create a method in the concern called `<record_type>_roles` (e.g. `collection_roles`)
4. Add the method to the array of method names in [Ability#ability_logic](app/models/ability.rb`)
5. Within the `<record_type>_roles` method in the ability concern, add [CanCanCan](https://github.com/CanCanCommunity/cancancan) rules for each role, following that role's specific criteria.
  - When adding/removing permissions, get as granular as possible.
  - Beware using `can :manage` -- in CanCanCan, `:manage` [refers to **any** permission](https://github.com/CanCanCommunity/cancancan/blob/develop/docs/Defining-Abilities.md#the-can-method), not just CRUD actions.
    - E.g. If you want a role to be able to _create_, _read_, _edit_, _update_, but not _destroy_ Users
    ```ruby
    # Bad - could grant unwanted permissions
    can :manage, User
    cannot :destroy, User

    # Good
    can :create, User
    can :read, User
    can :edit, User
    can :update, User
    ```
  - CanCanCan rules are [hierarchical](https://github.com/CanCanCommunity/cancancan/blob/develop/docs/Ability-Precedence.md):
    ```ruby
    # Will still grant read permission
    cannot :manage, User # remove all permissions related to users
    can :read, User
    ```
6. Add new / change existing `#can?` ability checks in views and controllers where applicable

### Search Permissions Notes
- Permissions are injected in the solr query's `fq` ("filter query") param ([link to code](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/enforcement.rb#L56))
- Enforced (injected into solr query) in [Blacklight::AccessControls::Enforcement](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/enforcement.rb) 
- Represented by an instance of `Blacklight::AccessControls::PermissionsQuery` (see [#permissions_doc](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/permissions_query.rb#L7-L14))
- Admin users don't have permission filters injected when searching ([link to code](https://github.com/samvera/hyrax/blob/v2.9.0/app/search_builders/hyrax/search_filters.rb#L15-L20))
- `SearchBuilder` may be related to when permissions are and aren't enforced 
- Related discussion in Slack: [inheritance question](https://samvera.slack.com/archives/C0F9JQJDQ/p1614103477032200)