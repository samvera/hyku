# Persistence Layer Introduction

For Hyku 6, we’re planning to leverage the Freyja adapter from the [Hyrax double\_combo work](https://github.com/samvera/hyrax/pull/6221).  In short, the Freyja adapter first checks postgres, then checks Fedora 4.

When we read from a Valkyrie double combo adapter we perform the following: `first_layer.find || second_layer.find` (e.g. check Postgres, failing that check ActiveFedora).

When we write/save/update a Valkyrie double combo adapter we perform the following: `first_layer.write`.  We never update the second layer.

# State of Data Considerations

With the above intro to the persistence layer strategy we need to consider that existing Hyku applications already have data.  And there are three scenarios we must address:

1.  Created via ActiveFedora, not yet migrated.
2.  Created via ActiveFedora, then migrated.
3.  Created via Valkyrie, would not be migrated.

Further, we need to consider the foundational AdminSet; this follows the same logic of the above.

When we create a tenant using Valkyrie, with a Frigg/Freyja adapter, we create an admin set.  The admin set will be written to the “first” storage layer (<abbr title="example given">e.g.</abbr> Postgres or Fedora6) but not the “second” layer (<abbr title="example given">e.g.</abbr> Fedora 4).  What that means is when we go to create an ActiveFedora::Base work, we are attempting to write the work to Fedora 4 within the AdminSet’s node.  However, since the admin set was not created in Fedora 4, we encounter an error.

## Example Spec Problem

```ruby
let!(:admin_set) do
  admin_set = AdminSet.new(title: ['Test Admin Set'])
  allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('default')
  Hyrax::AdminSetCreateService.call!(admin_set:, creating_user: nil)
end

let!(:work) { process_through_actor_stack(build(:work), work_depositor, admin_set.id, visibility) }
```

We use the very helpful `Hyrax::AdminSetCreateService` to do all of the complex admin set type things.  This ends up creating the file in the “first” layer, but not the second.  Then when we create the work, we’re using the `process_through_actor_stack` which is sending everything through ActiveFedora::Base.  Hence we get an LDP error:

```shell
Ldp::BadRequest:
       javax.jcr.PathNotFoundException: No node exists at path '/hykudemo/f9/a7/62/79/f9a76279-a659-4a5d-ba3e-e7ba8d82849e' in workspace "default"
```

## Test Strategy Approach

1.  We create an AdminSet via ActiveFedora
    a. We create works via ActiveFedora; then read via Valkyrie
2.  We create an AdminSet via Valkyrie
    a. We create works via Valkyrie

There are 2 strategies, starting from ActiveFedora and starting from Valkyrie.

When starting from ActiveFedora:

-   We need a persisted ActiveFedora AdminSet with proper permission template setup.
-   We likely need to specify for the context of the spec what the AdminSet model is.
-   We need to create works via ActiveFedora; note the “process\_through\_actor\_stack” above.

When starting from Valkyrie:

-   We can leverage the Hyrax::AdminSetCreateService to create the AdminSet
-   We should specify the AdminSet model for the test scope
-   We create works via the Transaction stack (see the hot new `Hyrax::Action::CreateValkyrieWork` in `double_combo`)

We also have available to us all of the Hyrax `spec/factories` to extend  

# Indexing Considerations

**Problem:** The implementation of `Hyrax::SolrService` and `ActiveFedora::SolrService` is not identical.  Which means there are implications on Hyku switches the solr connection for each tenant.

**Design Goal:** The primary goal is that we want to ensure that the different mechanisms for querying Solr are abiding by the tenant switching logic.

**Connection Sources:** In reviewing how we are interacting with Solr, there are three primary mechanisms:

-   **`ActiveFedora::SolrService`:** Older code favors this implementation.
-   **`Hyrax::SolrService`:** This *almost* a direct replacement of `ActiveFedora::SolrService`, but there are interface differences.  We have begun moving code to use this service class.
-   **`Hyrax.index_adapter`:** This is part of reading/writing to Valkyrie.

When `Hyrax.config.query_index_from_valkyrie` is true, the `Hyrax::SolrService` uses `Hyrax.indexing_adapter`.

When `Hyrax.config.query_index_from_valkyrie` is false, the `Hyrax::SolrService` uses `ActiveFedora::SolrService`.
