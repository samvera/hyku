# Multi-tenant domain model

The [`Apartment` gem](https://github.com/influitive/apartment) segments the application into one or more `Apartment` tenants.

`Account` is a global model, i.e., one that isn't scoped to an `Apartment` tenant. An `Account` has one or more `Apartment` tenants.

`Site` is a singleton that we use to effectively namespace, e.g., `application_name` values. A `Site` maps 1-to-1 onto an `Apartment` tenant. A `Site` belongs to an `Account`.

`User` has one or more `Roles`. `Users` are defined within `Apartment` tenant scope.

Some `Roles` are scoped to `Sites`; some aren't. There is a many-to-many relationship between `Roles` and `Users`. We currently have two `Roles` defined: Site admins and superadmins.

`Abilities` use `Roles` to make authorization decisions on `Resources` (terminology from the rolify gem).

# Using account-switching in development

* Flip the `multitenancy.enabled` setting in [config/settings.yml](https://github.com/projecthydra-labs/hybox/blob/master/config/settings.yml#L7) to `true` (but don't commit this later)
* To support a multitenant setup locally, you'll need to ensure your localhost can respond to multiple subdomains (as each tenant is a subdomain). There's a few options for doing so:
   * Option 1: Use the `lvh.me` registered domain (which just points at 127.0.0.1) as your configured `multitenancy.admin_host` in [config/settings.yml](https://github.com/projecthydra-labs/hybox/blob/master/config/settings.yml#L9). This will mean that your main application will be available at http://lvh.me:3000 and a tenant named "test" would be at http://test.lvh.me:3000
   * Option 2: Set up some localhost IPs (one per tenant) in `/etc/hosts` (or similar), e.g.:
     ```
     127.0.2.1       foo
     127.0.3.1       bar
     ```
     * On OSX 10.11.6, it was also necessary to disable low level packet filtering to allow connections to the additional local IPs, as documented [here](https://gist.github.com/atz/0fb87891dd11d291d282947e4607fed9):
        ```bash
        sudo pfctl -d
        ```
* When starting Hyku, be sure to bind the rails server to 0.0.0.0 so that all of your tenants respond to HTTP requests: 
  ```
  rails s -b 0.0.0.0
  ```
* To manage your tenants, you'll want to have at least one SuperAdmin user. So, grant one of your users "superadmin" rights. (Note: The square brackets around the email address are 
required)
  ```
  rake superadmin:grant[user@email.org]
  ```
* Once your application is started, you can login as a superadmin using the "Administrator Login" option in the footer. Once logged in, you'll be able to create a new repository (tenant) or see currently existing tenants via an "Accounts" menu option in header.
