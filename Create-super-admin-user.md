To manage your tenants, you'll want to have at least one superadmin user. This user must be a "global" user (i.e. not specific to a tenant)

# Create a global user:
1. In your browser, click the "Administrator Login" link in the footer of the homepage. Then click "Sign up" to create a global user account.

# Make global user *super*:
2. [SSH to the webapp instance in the stack](https://github.com/samvera-labs/hyku/wiki/SSH-to-AWS-demo-stack)
3. Change to the application directory
```shell
cd /var/app/current
```
4. Use the `superadmin` rake task to provide superadmin rights. The square brackets around the email address are required. (Because we use some gems from github we need to set the BUNDLE_PATH first.)
```shell
BUNDLE_PATH=/opt/rubies/ruby-2.3.4/lib/ruby/gems/2.3.0/ bundle exec rake superadmin:grant[user@email.org]
```
5. Back in the browser, log out and in again using the "Administrator Login" option in the footer. Once logged in, you'll be able to create a new repository (i.e. tenant) or see currently existing tenants via an "Accounts" menu option in header.