# Groups with Roles
## Role Set Creation Guidelines
1. Add role names to the [RolesService::ALL_DEFAULT_ROLES](app/services/roles_service.rb) constant
2. Create a `<role_name>?` method for each role you are adding in the [GroupAwareRoleChecker](app/services/group_aware_role_checker.rb)
3. Find related ability concern in Hyrax (if applicable)
  - Look in `app/models/concerns/hyrax/ability/` (local repo first, then Hyrax's repo)
  - E.g. ability concern for Collections is `app/models/concerns/hyrax/ability/collection_ability.rb`
  - If a concern matching the record type exists in Hyrax, but no the local repo, copy the file into the local repo
    - Be sure to add override comments (use the `OVERRIDE:` prefix)
  - If no concern matching the record type exists, create one.
    - E.g. if creating an ablility concern for the `User` model, create `app/models/concerns/hyrax/ability/user_ability.rb`
4. Create a method in the concern called `<record_type>_roles` (e.g. `collection_roles`)
5. Add the method to the array of method names in [Ability#ability_logic](app/models/ability.rb`)
6. Within the `<record_type>_roles` method in the ability concern, add [CanCanCan](https://github.com/CanCanCommunity/cancancan) rules for each role, following that role's specific criteria.
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
    cannot :destroy, User
    ```
  - CanCanCan rules are [hierarchical](https://github.com/CanCanCommunity/cancancan/blob/develop/docs/Ability-Precedence.md):
    ```ruby
    # Will still grant read permission
    cannot :manage, User # remove all permissions related to users
    can :read, User
    ```
7. Add new / change existing `#can?` ability checks in views and controllers where applicable

## Other Information
- If any minor / self-contained overrides (e.g. overriding a single method) to any dependencies (hyku, hyrax, hydra-access-controls, etc.) need to be made, add them in [config/initializers/permissions_overrides.rb](config/initializers/permissions_overrides.rb)
- Add [ability specs](spec/abilities) and [feature specs](spec/features)

### Search Permissions 
- Permissions are injected in the solr query's `fq` ("filter query") param ([link to code](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/enforcement.rb#L56))
- Enforced (injected into solr query) in [Blacklight::AccessControls::Enforcement](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/enforcement.rb) 
- Represented by an instance of `Blacklight::AccessControls::PermissionsQuery` (see [#permissions_doc](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/permissions_query.rb#L7-L14))
- Admin users don't have permission filters injected when searching ([link to code](https://github.com/samvera/hyrax/blob/v2.9.0/app/search_builders/hyrax/search_filters.rb#L15-L20))
- `SearchBuilder` may be related to when permissions are and aren't enforced 
- Related discussions in Slack: 
  - [first inheritance question](https://samvera.slack.com/archives/C0F9JQJDQ/p1614103477032200)
  - [second inheritance question](https://notch8.slack.com/archives/CD47U8QCQ/p1615935043012800)
