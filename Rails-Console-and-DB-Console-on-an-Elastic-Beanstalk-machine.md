### Application directory
Start in the correct location.
```
cd /var/app/current
```

### Rails console
Because we use some gems from github we need to set the `BUNDLE_PATH` first
```shell
BUNDLE_PATH=/opt/rubies/ruby-2.3.1/lib/ruby/gems/2.3.0/ bundle exec rails c production
```

In console, if you want to switch to a specific tenant:
```ruby
AccountElevator.switch!('nacho.demo.hydrainabox.org')
```

### Rails db console
For direct postgres access:
```shell
BUNDLE_PATH=/opt/rubies/ruby-2.3.1/lib/ruby/gems/2.3.0/ RAILS_ENV=production bundle exec rails db -p
```
The `-p` is required to pickup DB user/pass from app configuration.

**Remember**: the Apartment gem makes extensive use of schemas, so you **must** be sure you are looking at the right table!