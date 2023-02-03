# Groups with Roles

## Table of Contents
  * [Setup an Existing Application to use Groups with Roles](#setup-an-existing-application-to-use-groups-with-roles)
  * [Role Set Creation Guidelines](#role-set-creation-guidelines)
    * [Search Permissions Notes](#search-permissions-notes)
  * [Using the Feature](#using-the-feature)

---

## Setup an Existing Application to use Groups with Roles

These rake tasks will create data across all tenants necessary to setup Groups with Roles. **Run them in the order listed below.**

Prerequisites:
- All Collections must have CollectionTypes _and_ PermissionTemplates (see the **Collection Migration** section in the [Hyrax 2.1 Release Notes](https://github.com/samvera/hyrax/releases/tag/v2.1.0))

```bash
rake hyku:roles:create_default_roles_and_groups
rake hyku:roles:create_collection_accesses
rake hyku:roles:create_admin_set_accesses
rake hyku:roles:create_collection_type_participants
rake hyku:roles:add_admin_users_to_admin_group
rake hyku:roles:grant_workflow_roles
rake hyku:roles:destroy_registered_group_collection_type_participants # optional
```

<sup>\*</sup> The `hyku:roles:destroy_registered_group_collection_type_participants` task is technically optional. However, without it, collection readers will be allowed to create Collections.

Default `Role`s and `Hyrax::Group`s are seeded into an account (tenant) at creation time (see [CreateAccount#create_defaults](app/services/create_account.rb)), so these only need to be run once.

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

## Using the feature
[Managing Users, Groups and Permissions](https://docs.google.com/document/d/1dQta2JaT0rLPibl9XZNVt5VLskEWL9Ojym8EFKGdHYE/edit#heading=h.rrrlo1kmlxki)
