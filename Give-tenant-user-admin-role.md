To give an existing user in a tenant admin role:

## Setup
1. SSH to the webapp instance in the stack, [see instructions here](https://github.com/samvera-labs/hyku/wiki/SSH-to-AWS-demo-stack)
2. Open a rails console, [see instructions here](https://github.com/samvera-labs/hyku/wiki/Rails-Console-and-DB-Console-on-an-Elastic-Beanstalk-machine)

## Add admin role
1. Switch into the tenant: `AccountElevator.switch!('tenant.host.name.here')`
2. Grab the user instance: `user = User.find_by(email: 'some.person@institution.edu')`
3. Add the role for the current site instance: `user.add_role(:admin, Site.instance)`