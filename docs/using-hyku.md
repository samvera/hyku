# Using Hyku

*This guide assumes a docker installation of Hyku. If you are not using docker, you may need to adjust the commands accordingly.*

## Create a global admin user

To manage your tenants, you'll want to have at least one superadmin user. This user must be a "global" user (i.e. not specific to a tenant)

After navigating to the Hyku main dashboard, you can create this user by clicking **Administrator Login** in the footer, of the homepage. Then click **Sign up** to create a new user.

### Granting superadmin privileges

To grant superadmin privileges to a user, you can run the following command:

```bash
docker compose exec rake hyku:superadmin:grant[user@email.org]
```

## Create your first tenant

Click on the **Get Started** link on the Hyku dashboard, where you will be prompted to create your first tenant.

By default, the tenant will be created as "private" which will require users to provide HTTP Basic Auth credentials to access the site. You can change this setting in the tenant settings.

The default credentials are:

- **Username**: `samvera`
- **Password**: `hyku`


## Importing
### Bulkrax:

Bulkrax is enabled by default and CSV, OAI and XML importers can be used in the admin dashboard or through the command line API.
More info about configuring and using bulkrax can be found [here](https://github.com/samvera-labs/bulkrax/wiki)
