To give an existing user the tenant admin role. This role allows the user to manage/administer a single, specific tenant.

## Via SuperAdmin UI

1. Login to global tenant as a superadmin user. If you don't yet have a superadmin, see [[Create super admin user]]
2. Click on the "Accounts" menu in the header
3. Find the tenant in the list of tenants, and click the "Manage" button next to that tenant.
4. You will now see a list of all current tenant administrators, along with an option to "Add or invite new administrator (via email)"
5. To add a new tenant administrator, simply enter their email address and click "Add".
    * If the user already has an account (associated with that email address) on that tenant, they will immediately become an administrator of that tenant.
    * If the user does not yet have an account on that tenant, they will receive an email invitation to create an account. After creating an account, they will become an administrator of that tenant.

## Via Commandline
### Setup
1. SSH to the webapp instance in the stack, [see instructions here](https://github.com/samvera-labs/hyku/wiki/SSH-to-AWS-demo-stack)
2. Open a rails console, [see instructions here](https://github.com/samvera-labs/hyku/wiki/Rails-Console-and-DB-Console-on-an-Elastic-Beanstalk-machine)

### Add admin role
1. Switch into the tenant: `AccountElevator.switch!('tenant.host.name.here')`
2. Grab the user instance: `user = User.find_by(email: 'some.person@institution.edu')`
3. Add the role for the current site instance: `user.add_role(:admin, Site.instance)`