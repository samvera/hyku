
## Default: Admin-only tenant creation

By default, only a superadmin can create a new tenant. If you don't yet have a superadmin, see [[Create super admin user]].

After logging in as a superadmin, you'll see a "Get Started" option to create your first tenant. Alternatively, you can create/manage tenants via the "Accounts" menu.

## Allowing anyone to create a tenant

In some scenarios, namely for demonstration, development or testing, it may be desirable to allow anyone to create a new tenant.

To allow anyone to create a tenant, flip the `multitenancy.admin_only_tenant_creation` setting in `config/settings.yml` to `false`
  ```
  multitenancy:
    enabled: true
    ...
    admin_only_tenant_creation: false
  ```

With this option set to false, anonymous users will be allowed to create new tenants (and become immediate administrators of the new tenant). Obviously, this should never be set to `false` in any publicly available, production site.

Please note that even if this setting is `false`, only superadmin users will be able to manage/delete tenants. This feature simply provides a way to quickly create new tenants (for demo/test sites) without requiring a superadmin account to be setup for each tenant creator.
