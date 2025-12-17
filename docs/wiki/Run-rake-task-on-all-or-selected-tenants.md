To run the `rake user:list[email,foobar]` task within the context of all tenants:
* `rake tenantize:task[user:list,email,foobar]`

To run the task only in specified tenants, use an environment variable named tenants, with each tenant cname separated by a space: 
* `rake tenantize:task[user:list,email,foobar] tenants="foo.localhost baz.localhost quuuuux.localhost"`

See [code for this feature here](https://github.com/samvera-labs/hyku/pull/1391)