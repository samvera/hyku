Because we use some gems from github we need to set the `BUNDLE_PATH` first
```shell
$ cd /var/app/current
$ BUNDLE_PATH=/opt/rubies/ruby-2.3.1/lib/ruby/gems/2.3.0/ bundle exec rails c production
```

If you want to switch to a specific tenant:
```ruby
AccountElevator.switch!('nacho.demo.hydrainabox.org')
```