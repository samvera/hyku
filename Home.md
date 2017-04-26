# Multi-tenant domain model

`Apartment` segments the application into one or more `Apartment` tenants.

`Account` is a global model, i.e., one that isn't scoped to an `Apartment` tenant. An `Account` has one or more `Apartment` tenants.

`Site` is a singleton that we use to effectively namespace, e.g., `application_name` values. A `Site` maps 1-to-1 onto an `Apartment` tenant. A `Site` belongs to an `Account`.

`User` has one or more `Roles`. `Users` are defined within `Apartment` tenant scope.

Some `Roles` are scoped to `Sites`; some aren't. There is a many-to-many relationship between `Roles` and `Users`. We currently have two `Roles` defined: Site admins and superadmins.

`Abilities` use `Roles` to make authorization decisions on `Resources` (terminology from the rolify gem).

# Using account-switching in development

Set up some localhost IPs (one per tenant) in /etc/hosts, e.g.:

```
127.0.2.1       foo
127.0.3.1       bar
```

Flip the `multitenancy.enabled` setting in [config/settings.yml](https://github.com/projecthydra-labs/hybox/blob/master/config/settings.yml#L2) to `true` (but don't commit this later)

Bind the rails server to 0.0.0.0 so that all of your tenants respond to HTTP requests: `rails s -b 0.0.0.0` 

On OSX 10.11.6, it was also necessary to disable low level packet filtering to allow connections to the additional local IPs, as documented [here](https://gist.github.com/atz/0fb87891dd11d291d282947e4607fed9):
```bash
sudo pfctl -d
```