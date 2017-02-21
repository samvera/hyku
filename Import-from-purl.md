1. SCP the file with the druids in it to the webapp/worker server. In this example I'm using `select_band.txt`
1. SSH to the webapp/worker server
1. `cd /var/app/current`
1. Run this:
```
BUNDLE_PATH=/opt/rubies/ruby-2.3.1/lib/ruby/gems/2.3.0/ RAILS_ENV=production DISABLE_REDIS_CLUSTER=true \
bundle exec bin/import_from_purl nacho.demo.hydrainabox.org jcoyne85@stanford.edu ~/select_band.txt
```