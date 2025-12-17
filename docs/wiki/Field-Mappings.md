> [!IMPORTANT]
> This article assumes that you understand the basics of [how field mappings work in Bulkrax](https://github.com/samvera/bulkrax/wiki/Configuring-Bulkrax#field-mappings).

# Bulkrax Field Mappings in Hyku

In both Hyrax and older versions of Hyku (< v7.0.0), field mappings are configured in the Bulkrax initializer (`config/initializers/bulkrax.rb`). *This is not where field mappings should be configured in Hyku.*

Instead, field mappings can be configured in two different locations:

1. In a custom initializer
1. In a tenant's `Account` settings

Each location serves a different purpose as explained below.

## Hyku default field mappings

Hyku's set of default field mappings can be found in `config/application.rb`. They are accessed using `Hyku.default_bulkrax_field_mappings` and can be overwritten directly in that method or by using `Hyku.default_bulkrax_field_mappings=` in an initializer.

> [!NOTE]
> For `hyku_knapsack` applications, overriding the defaults directly in `confing/application.rb` is not feasible. In this case, using `Hyku.default_bulkrax_field_mappings=` in an initializer is the preferred method.

This set of default mappings is what every newly-created tenant will be initialized with. Some institutions may find use in overriding the pre-configured defaults. An example of when this could be useful is as follows:

> I manage a multi-tenant Hyku application. Most of my tenants import CSVs that conform to the same structure. However, instead of the CSVs having a column called "title", it's called "primary".

This would be a good reason to override Hyku's default mappings to add `primary` as a column that will map to `title`. Doing this in the defaults means the same mapping won't need to be configured in each individual tenant separately.

## Per-tenant field mappings

Hyku supports the ability to configure field mappings on a per-tenant basis. This is done via the tenant's `Account` settings. `Account` settings can be accessed by admins from within the tenant: Dashboard > Settings > Accounts (`/admin/account/edit`). They can also be accessed by superadmins via the proprietor views (`/proprietor/accounts/<id>/edit`).

By default, the `Bulkrax Field Mappings` input on the Account settings form is pre-populated with [*Hyku's* default field mappings](#hyku-default-field-mappings) (not Bulkrax's).

## Additional details
### Order of precedence

Hyku will look for field mappings in this order:

Tenant-specific `Account` setting? -> Hyku's default field mappings? -> Bulkrax's default field mappings

> [!NOTE]
> Unless you explicitly unset Hyku's default field mappings, Bulkrax's defaults will never be used.

### Merging field mapping configs

Currently, field mapping configurations do not merge with each other. If Hyku finds a set of field mappings in the current tenant's `Account` setting, it will use exactly what's there and stop "looking". It will **not** take what's in the `Account` setting and try to merge / reconcile it with Hyku's defaults. Similarly, Hyku's defaults do not attempt to merge with Bulkrax's defaults. Each set of configured field mappings is intended to be able to stand on its own as a complete and valid set, not build on top of another set.
