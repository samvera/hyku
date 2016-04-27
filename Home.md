# Multi-tenant domain model

`Apartment` segments the application into one or more `Apartment` tenants.

`Account` is a global model, i.e., one that isn't scoped to an `Apartment` tenant. An `Account` has one or more `Apartment` tenants.

`Site` is a singleton that we use to effectively namespace, e.g., `application_name` values. A `Site` maps 1-to-1 onto an `Apartment` tenant. A `Site` belongs to an `Account`.

`User` has one or more `Roles`. `Users` are defined within `Apartment` tenant scope.

Some `Roles` are scoped to `Sites`; some aren't. There is a many-to-many relationship between `Roles` and `Users`. We currently have two `Roles` defined: Site admins and superadmins.

`Abilities` use `Roles` to make authorization decisions on `Resources` (terminology from the rolify gem).

