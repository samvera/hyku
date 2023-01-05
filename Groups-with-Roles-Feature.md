# Groups with Roles

## Table of Contents
  * [Creating Default Roles and Groups](#creating-default-roles-and-groups)
  * [Setup an Existing Application to use Groups with Roles](#setup-an-existing-application-to-use-groups-with-roles)
  * [Role Set Creation Guidelines](#role-set-creation-guidelines)
    * [Other Information](#other-information)
  * [Search Permissions Notes](#search-permissions-notes)

---

## Creating Default Roles and Groups

Default `Roles` and `Hyrax::Groups` are seeded into an account (tenant) at creation time (see [CreateAccount#create_defaults](app/services/create_account.rb)).

To manually seed default `Roles` and `Hyrax::Groups` _across all tenants_, run this rake task:

```bash
rake hyku:roles:create_default_roles_and_groups
```

## Setup an Existing Application to use Groups with Roles

These rake tasks will create data across all tenants necessary to setup Groups with Roles. **Run them in the order listed below.**

Prerequisites:
- All Collections must have CollectionTypes _and_ PermissionTemplates (see the **Collection Migration** section in the [Hyrax 2.1 Release Notes](https://github.com/samvera/hyrax/releases?after=v2.2.0))

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

### Other Information
- For guidelines on overriding dependencies, see the [Overrides to Dependencies](README#overrides-to-dependencies) section of the README
- Add [ability specs](spec/abilities) and [feature specs](spec/features)

## Search Permissions Notes
- Permissions are injected in the solr query's `fq` ("filter query") param ([link to code](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/enforcement.rb#L56))
- Enforced (injected into solr query) in [Blacklight::AccessControls::Enforcement](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/enforcement.rb) 
- Represented by an instance of `Blacklight::AccessControls::PermissionsQuery` (see [#permissions_doc](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/permissions_query.rb#L7-L14))
- Admin users don't have permission filters injected when searching ([link to code](https://github.com/samvera/hyrax/blob/v2.9.0/app/search_builders/hyrax/search_filters.rb#L15-L20))
- `SearchBuilder` may be related to when permissions are and aren't enforced 
- Related discussions in Slack: 
  - [first inheritance question](https://samvera.slack.com/archives/C0F9JQJDQ/p1614103477032200)
  - [second inheritance question](https://notch8.slack.com/archives/CD47U8QCQ/p1615935043012800)

## Extra Resources
(Managing Users, Groups and Permissions)[https://docs.google.com/document/d/1dQta2JaT0rLPibl9XZNVt5VLskEWL9Ojym8EFKGdHYE/edit#heading=h.rrrlo1kmlxki]
