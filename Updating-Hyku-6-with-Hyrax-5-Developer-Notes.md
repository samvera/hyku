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

By configuration and convention, each ActiveFedora::Base work type will have a corresponding Valkyrie::Resource.  Consider that `GenericWork < ActiveFedora::Base`, we'll have `GenericWorkResource < Valkyrie::Resource`.

## `.internal_resource` and `.to_rdf_representation`

To leverage the existing Solr index without a migration means you'll want to ensure that the Valkyrie class's read and write similar Solr documents.  In paricular two attributes:

- `has_model` :: The specific conceptual model (e.g. Article, Monograph, AdminSet, Collection)
- `generic_type` :: The general conceptual model (e.g. Work, Work, AdminSet, Collection)

There's inconsistency between ActiveFedora and Valkyrie's index field for generic_type: `generic_type_sim` and `generic_type_si` respectively.

Hyrax has concistently used `has_model_ssim` as the Solr key.

To leverage the `double_combo` ensure that your Valkyrie::Resource models have `.internal_resource` and `.to_rdf_representation` that reflects the class you're migrating from.  The `double_combo` branch provides the `Hyrax::ValkyrieLazyMigration.migrating` class method to do the heavy lifting.

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

# User Interface Considerations

As Hyku moves to use the Goddess adapters of the [Double Combo pull request](https://github.com/samvera/hyrax/pull/6221), we want to have all Create/Read/Update/Delete (CRUD) operators performed on the conceptual work type's `Valkyrie::Resource`.  That is to say, if we had a `GenericWork` with `ID=1234-5678-abcd` when we operate on a work via the User Interface (UI) we want to operate on the `Valkyrie::Resource`.

To accomplish this, we need to consider three elements:

- Controller configuration
- Routing
- Form configuration

## Controller Configuration

At present, there's no compeling reason to have one controller for `GenericWork` and one controller for `GenericWorkResource`; in particular given that we do not want to expose a UI means of operating on a `GenericWork`.

Let's look at the `Hyrax::GenericWorksController`:

```ruby
  # frozen_string_literal: true

  # Generated via
  #  `rails generate hyrax:work GenericWork`
  module Hyrax
    # Generated controller for GenericWork
    class GenericWorksController < ApplicationController
      # Adds Hyrax behaviors to the controller.
      include Hyrax::WorksControllerBehavior
      include Hyku::WorksControllerBehavior
      include Hyrax::BreadcrumbsForWorks
      self.curation_concern_type = ::GenericWork

      # Use this line if you want to use a custom presenter
      self.show_presenter = Hyrax::GenericWorkPresenter
    end
  end
```

The two significant changes for each type of work is in the `class_attribute` configuration of `self.curation_concern_type=` and `self.show_presenter`.

If you need custom logic for your work, you can add it to the controller.  But in the author's experience ([@jeremyf](https://github.com/jeremyf), I don’t think I’ve seen customizations beyond the `class_attribute` configurations.

**Action Item:** Look to what all configuration options are available and reconfigure the controller to use the `GenericWorkResource` and it's corresponding expections.

## Routing Considerations

Ideally we would route both a `GenericWork` and a `GenericWorkResource` to the same controller...the one configured to handle the `GenericWorkResource`.

Further, we'd preserve the prior helper methods (e.g. `hyrax_generic_work_path(resource)`) as well as the polymorphic path for a resource (e.g. `polymoprhic_path([hyrax, resource])`).

## Form Configuration

When we render a form for a given work type there are two primary considerations:

- The `FORM` element and it's `action` attribute (in CSS selector speak that is `form[action]`).  This describes which URL we'll hit, and thus what route we hit.
- The `INPUT` elements `name` attribute (or `input[name]`).  For example `generic_work[title]` when we submit the form we'll see a `ApplicationController#params` that looks something like this: `{ generic_work: { title: 'Given Title' }`.

The `generic_work` portion of the `input[name]` comes from the form object's model_name's `@param_key`.  We derive the `form[action]` from the object's model_name's `@singular` for update/delete actions and `@plural` create actions.

## Conjecture (Now Confirmed)

For Hyku we will:

- configure the `GenericWorkController` to use `GenericWorkResource` 
- ensure that a `GenericWorkResource` and `GenericWork` produce the same routes, `form[action]`, and `input[name]`; this might be as simple as overwriting `GenericWorkResource.model_name` to call `GenericWork.model_name`; or for that glorious moment when `GenericWork` goes away maybe hand craft our own model name.
- ensure that when we edit things via the `GenericWorkController` we are editing the `GenericWorkResource`

This means that we are not registering `generic_work_resource` as a curation concern and instead relying on `generic_work` as the registered concern.  This way we won't have duplications in the UI for selecting the curation concern.

# Indexing Considerations

**Problem:** The implementation of `Hyrax::SolrService` and `ActiveFedora::SolrService` is not identical.  Which means there are implications on Hyku switches the solr connection for each tenant.

**Design Goal:** The primary goal is that we want to ensure that the different mechanisms for querying Solr are abiding by the tenant switching logic.

**Connection Sources:** In reviewing how we are interacting with Solr, there are three primary mechanisms:

-   **`ActiveFedora::SolrService`:** Older code favors this implementation.
-   **`Hyrax::SolrService`:** This *almost* a direct replacement of `ActiveFedora::SolrService`, but there are interface differences.  We have begun moving code to use this service class.
-   **`Hyrax.index_adapter`:** This is part of reading/writing to Valkyrie.

When `Hyrax.config.query_index_from_valkyrie` is true, the `Hyrax::SolrService` uses `Hyrax.indexing_adapter`.

When `Hyrax.config.query_index_from_valkyrie` is false, the `Hyrax::SolrService` uses `ActiveFedora::SolrService`.

## Difference between Hyrax's and ActiveFedora's SolrService

There are differences between the `Hyrax::SolrService` and `ActiveFedora::SolrService`.  One key consideration is that `ActiveFedora::SolrService` is a singleton class and `Hyrax::QueryService` is not.

The difference is important.  In the ActiveFedora case, we’d instantiate it once and then throughout the application always call that one instance.  Whereas with Hyrax, that query service is instantiated with each call to class methods.

Below is how `Hyrax::SolrService` implements it’s class methods (e.g. `.add`, `.commit`, etc.); namely it delegates the class methods to the `.new` method.  Meaning each time we call `Hyrax::SolrService.query` we are instantiating a new object.

```ruby
class Hyrax::SolrService
  def initialize(use_valkyrie: Hyrax.config.query_index_from_valkyrie)
    @old_service = ActiveFedora::SolrService
    @use_valkyrie = use_valkyrie
  end

  class << self
    ##
    # We don't implement `.select_path` instead configuring this at the Hyrax
    # level
    def select_path
      raise NotImplementedError, 'This method is not available on this subclass.' \
                                 'Use `Hyrax.config.solr_select_path` instead'
    end

    delegate :add, :commit, :count, :delete, :get, :instance, :ping, :post,
             :query, :query_result, :delete_by_query, :search_by_id, :wipe!, to: :new
  end
end
```

We still have the concept of `Hyrax::SolrService.instance`, though it delegates’s to `.new`; thus creating new connections each time.

# Access Control List (ACL) Considerations

A resources's ACLs are stored as a separate object in the persistence layer.

In the case of data that starts in Fedora (and created in ActiveFedora) we must consider that we might update an ACL object but not the assocated resource.  This is something that is done during lease and embargo expiry.

In the case of the Frigg and Freyja adapters:

- We look up objects first in Valkyrie then via ActiveFedora.
- When we expire a lease or embargo, we write/update the record in Valkyrie and do not touch the ActiveFedora object.

What this means is that the ACL in Valkyrie is different from ActiveFedora, yet were we to load the Work via ActiveFedora *or* via Frigg/Freyja, we'd only find the work via ActiveFedora.  Which, by default loads the ACL from ActiveFedora; something that is now out of sync.

<details>
<summary>Spec I used to track down ACL issues</summary>

From the [spec/jobs/lease_auto_expiry_job_spec.rb](https://github.com/samvera/hyku/blob/fc459450422815810aac37e13569bd2daf006117/spec/jobs/lease_auto_expiry_job_spec.rb).

The below spec failed on the Hyrax `double_combo` branch before [fdcabe651](https://github.com/samvera/hyrax/commit/fdcabe651).  [PR #6671](https://github.com/samvera/hyrax/pull/6671) provides the solution.

```ruby
it "Expires the lease on a work with expired lease", active_fedora_to_valkyrie: true do
  # Before we expire the lease:
  #
  # Work start in Fedora; then through Freyja we can find the work (by querying first Postgres then finding it in Fedora)
  # Lease start in Fedora; then through Freyja we can find the lease (by querying first Postgres then finding it in Fedora)

  # When we expire the lease:
  # We find in Fedora, and save via Freyja meaning we write to Postgres and do not update Fedora
  # Note, we do not update the ACL's resource (e.g. the work), which means it's only in Fedora and not postgres.

  # After when we check the lease:
  # We find the work in Fedora via Freyja, eg. it's not in Posgres
  # We should find the ACL in Postgres...why are we not seeing the update when we check?

  expect(work_with_expired_lease).to be_a_kind_of(GenericWork)
  expect(work_with_expired_lease.visibility).to eq('open')
  gwr = GenericWorkResource.find(work_with_expired_lease.id)

  expect(work_with_expired_lease.embargo_id == gwr.embargo_id).to eq(true)
  expect(work_with_expired_lease.lease_id == gwr.lease_id).to eq(true)
  expect(work_with_expired_lease.access_control_id == gwr.access_control_id).to eq(true)

  expect { Hyrax.query_service.services[0].find_by(id: gwr.lease_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
  expect { Hyrax.query_service.services[0].find_by(id: gwr.access_control_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
  expect(Hyrax.query_service.services[1].find_by(id: gwr.lease_id)).to be_a Hyrax::Lease
  expect(Hyrax.query_service.services[1].find_by(id: gwr.access_control_id)).to be_a Hyrax::AccessControl

  expect do
    expect do
      expect do
        expect do
          expect do
            ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
            LeaseAutoExpiryJob.perform_now(account)
          end.not_to change { GenericWorkResource.find(work_with_expired_lease.id).lease_id }
        end.not_to change { GenericWorkResource.find(work_with_expired_lease.id).embargo_id }
      end.not_to change { GenericWorkResource.find(work_with_expired_lease.id).access_control_id }
      # Yes, these are Hydra::AccessControl objects because that's their internal_resource name
      # TODO: Find the map to get the right model for the Hyrax::AccessControl
    end.to change { Hyrax.query_service.services[0].count_all_of_model(model: Hydra::AccessControl) }.by(1)
  end.to change {  GenericWorkResource.find(work_with_expired_lease.id).visibility }
           .from('open')
           .to('restricted')

  # @orangewolf: Are we expecting to write the Leases into Postgres.  I assume so.

  # After update of the lease...
  # ...the work will not be in Postgres
  expect { Hyrax.query_service.services[0].find_by(id: work_with_expired_lease.id) }.to raise_error
  # ...the work will be in Fedora and accessible via the Wings adapter
  generic_work_from_wings = Hyrax.query_service.services[1].find_by(id: work_with_expired_lease.id)
  expect(generic_work_from_wings).to be_a(GenericWorkResource)

  # Here's the problem:
  #
  # - Work and ACL in Fedora but not Postgres
  # - We update the lease, which write the lease to postgres; but not write the work to Postgres
  # - We query the work; it's in Fedora and wings converts it to a Resource but then used the
  #   Fedora ACL (that is the one we didn't update)


  # Verifying that the underlying access control model and the corresponding change_set are
  # identical.  This is the implementation details of the Hyrax::AccessControlList model.
  # access_control_model = Hyrax::AccessControl.for(resource: GenericWorkResource.find(work_with_expired_lease.id))
  # access_control_model_change_set = Hyrax::ChangeSet.for(access_control_model)
  # expect(access_control_model.permissions).to eq(access_control_model_change_set.permissions)

  gwr = GenericWorkResource.find(work_with_expired_lease.id)

  acl = Hyrax.query_service.services[0].find_by(id: gwr.access_control_id)
  gwr_acl = gwr.permission_manager.acl

  # Here we have the failing spec.
  # The access control model says one thing but what we get from the cached permission manager.
  expect(gwr_acl.permissions).to eq(Set.new(gwr_acl.send(:access_control_model).permissions))

  # The ACL's written to service[0] are equal to the permissions that we derive from a fresh
  # Hyrax::AccessControlList
  expect(Set.new(acl.permissions)).to eq(Hyrax::AccessControlList.new(resource: gwr).permissions)

  # The ACLs in the system should be correct.  And the underlying permission manager fetches the
  # correct access_control_mdoel.
  expect(Set.new(acl.permissions)).to eq(Set.new(gwr_acl.send(:access_control_model).permissions))
end
```

</summary>
