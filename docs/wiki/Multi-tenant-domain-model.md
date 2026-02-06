In Hyku, each tenant is managed by an [`Account`](https://github.com/projecthydra-labs/hyku/blob/master/app/models/account.rb). `Account` segments the application data as follows:
* First, a unique identifier for the tenant (a random UUID) is generated
* The [`Apartment` gem](https://github.com/influitive/apartment) is used to segment the application database. In the PostgreSQL database, this segmentation occurs via database schemas. So, each Hyku tenant stores its data in its own database schema. (_NOTE: Apartment also calls these segments "tenants". But, in Hyku, a tenant encompasses a bit more, as you will see below._)
   * It is worth noting that most models become scoped to an `Apartment` tenant (i.e. they apply to a specific tenant's database schema). However, `Account` is a global model, as it manages the tenant. 
* A Solr Collection is created specific to the tenant (named with the tenant UUID). All objects in this tenant will be indexed into that collection.
* A Fedora Container is created specific to the tenant (named with the tenant UUID). All objects in this tenant will be stored in this container.
* A Redis namespace is created specific to the tenant (named with the tenant UUID).
* A [`Site`](https://github.com/projecthydra-labs/hyku/blob/master/app/models/site.rb) is created on the tenant. The `Site` corresponds to this tenant's Hyku application (and is configured to use the defined database schema, Solr collection, Fedora container, etc). `Site` is a singleton that we use to effectively namespace, e.g., `application_name` values.

Other models to be aware of:
* Application users are managed by the [`User` model](https://github.com/projecthydra-labs/hyku/blob/master/app/models/user.rb). Each `User` has one or more `Roles`. `Users` are defined within a tenant scope (using `Apartment`). So, if a user has a login for multiple Sites, those logins are stored separately (and may have different passwords, etc).
* Some `Roles` are scoped to `Sites`; some aren't. There is a many-to-many relationship between `Roles` and `Users`. We currently have two `Roles` defined: Site admins and SuperAdmins. SuperAdmins can create/manage tenants, while a Site admin is only an admin in a specific tenant.
* `Abilities` use `Roles` to make authorization decisions on `Resources` (terminology from the [rolify gem](https://github.com/RolifyCommunity/rolify)).
