## If the CreateSolrCollectionJob failed
Then you'll have a bunch of accounts without solr collections. These are not useful. Clean them up with:
```ruby
Account.where(solr_endpoint_id:nil).each do |account|
  Apartment::Tenant.drop(account.tenant)
  account.destroy
end
```