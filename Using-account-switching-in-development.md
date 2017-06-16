* Flip the `multitenancy.enabled` setting in [config/settings.yml](https://github.com/projecthydra-labs/hybox/blob/master/config/settings.yml#L7) to `true` (but don't commit this later)
  ```
  multitenancy:
    enabled: true
  ```
* To support a multitenant setup locally, you'll need to ensure your localhost can respond to multiple subdomains (as each tenant is a subdomain). There's a few options for doing so:
   * Option 1: Use the `lvh.me` registered domain (which just points at 127.0.0.1) as your configured `multitenancy.admin_host` in [config/settings.yml](https://github.com/projecthydra-labs/hybox/blob/master/config/settings.yml#L9). This will mean that your main application will be available at http://lvh.me:3000 and a tenant named "test" would be at http://test.lvh.me:3000
     ```
     multitenancy:
       ...
       admin_host: lvh.me
     ```
   * Option 2: Use dnsmasq per http://evans.io/legacy/posts/wildcard-subdomains-of-localhost/. (Tested successfully on Ubuntu.)
   * Option 3: Set up some localhost IPs (one per tenant) in `/etc/hosts` (or similar), e.g.:
     ```
     127.0.2.1       foo
     127.0.3.1       bar
     ```
     * On OSX 10.11.6, it was also necessary to turn off `System Preferences > Security & Privacy > Firewall` and/or disable low level packet filtering to allow connections to the additional local IPs, as documented [here](https://gist.github.com/atz/0fb87891dd11d291d282947e4607fed9):
        ```bash
        sudo pfctl -d
        ```
* When starting Hyku, be sure to bind the rails server to 0.0.0.0 so that all of your tenants respond to HTTP requests: 
  ```
  rails s -b 0.0.0.0
  ```
* To manage your tenants, [you'll want to have at least one superadmin user.](https://github.com/samvera-labs/hyku/wiki/Create-super-admin-user)