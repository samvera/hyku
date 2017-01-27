## If the CreateSolrCollectionJob failed
Then you'll have a bunch of accounts without solr collections. These are not useful. Clean them up with:
```ruby
Account.where(solr_endpoint_id:nil).each do |account|
  Apartment::Tenant.drop(account.tenant)
  account.destroy
end
```

## If the solr collections were deleted
Find the accounts with missing collections and submit CreateSolrCollectionJob for each
```ruby
accounts_to_create = Account.all.map { |a| a.switch { a unless a.solr_endpoint.ping } }.compact
accounts_to_create.map { |account| CreateSolrCollectionJob.perform_later(account) }
```
When the jobs have completed each account should have a collection again.


## we want to destroy these accounts:
```
accounts_to_create.map(&:id)
=> [1, 25, 2, 3, 5, 7, 8, 37, 10, 38, 11, 39, 12, 41, 15, 14, 16, 43, 17, 44, 18, 46, 20, 21, 48, 22, 49, 23, 50, 24, 53, 54, 55, 56]
```