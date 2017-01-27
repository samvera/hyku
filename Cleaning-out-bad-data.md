## If the CreateSolrCollectionJob failed
Then you'll have a bunch of accounts without solr collections. These are not useful. Clean them up with:
```ruby
Account.where(solr_endpoint_id:nil).each do |account|
  Apartment::Tenant.drop(account.tenant)
  account.destroy
end
```

## If the solr collections were deleted
First find the accounts with missing collections:
```ruby
accounts_to_create = Account.all.map { |a| a.switch { a unless a.solr_endpoint.ping } }.compact
accounts_to_create.map { |account| CreateSolrCollectionJob.perform_later(account) }
```
