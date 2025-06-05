# Migrating to Valkyrie

(**Note:** In most instances, Notch8 uses Rancher for managing our server deployment, and GoodJob as our ActiveJob backend. The following documentation references these products.)

The migration process runs the same logic as the lazy migration that occurs in the freyja persister, based on the `valkyrie_transition?` setting. Prior to migrating works, it is important to migrate all admin sets and collections. This is done by submitting MigrateResourcesJob.perform_later. Default behavior submits migration for models AdminSet and Collection. If the models are named differently, you can specify the models to migrate in the job.

Correct migration of the all collections should be verified prior to beginning to migrate works. Compare the number of admin sets and collections overall to the number that exist in the resource table `Valkyrie::Persistence::Postgres::ORM::Resource` to ensure that all were migrated correctly.

Once collections have been migrated, works can be migrated by using the Reprocessor to migrate a list of ids. As a work is migrated, the freyja persister triggers the migration of its member works and file sets, and the corresponding Sipity::Entity.

Queued indexing can also be set up to speed up the overall process. The queued indexer can be enabled everywhere with `HYKU_USE_QUEUED_INDEX` or in the worker only with `HYKU_QUEUED_RUNNER`

### The Hyku Reprocessor

The Hyku Reprocessor allows iterating through large sets of ids. There are two steps for any reprocessing:
1. Store all the ids for processing to an `id.logs` file
2. Run a lambda against every id.

### Using the Reprocessor for a migration
In your rails console, switch to the tenant. For each tenant needing migration, you will follow the steps below.

Migration jobs include:
- MigrateResourcesJob
- MigrateFilesToValkyrieJob
- ContentUpdateEventJob

The number of jobs will expand, as each original MigrateResourcesJob submits the subsequent jobs. You can judge progress by monitoring when the number of queued jobs begins to decrease.
#### 1. Create a context for the Reprocessor to run

```
require 'reprocessor'
Reprocessor.load('tmp/imports')
```
#### 2. Load the ids in a file

First, set up a solr query to collect the ids you want to reprocess... for example:
```
search = "-is_child_bsi:true AND has_model_ssim:(#{Bulkrax.curation_concerns.join(' OR ')})"
```
Once you have the correct search, export the search into the ids file. Open the `tmp/imports` dicrectory to make sure there isn't already a file called `ids.log`. If there is, rename it. Then run the search in the rails console to create the new `ids.log` file.
```
Reprocessor.capture_with_solr(search)
```
If you need to revise the search, you will need to reset the location. Otherwise it will find the records but won't actually process any or them.
```
Reprocessor.current_location = 0
```
#### 3. Stop the workers & submit the jobs

Stopping the workers allows you to update the scheduled date before the jobs run, so you can release the jobs in batches.

Reset the reprocessor location, and run the lambda to submit all of the migration jobs for the ids.
```
Reprocessor.current_location = 0
Reprocessor.process_ids(Reprocessor.lambda_migrate_resources)
```
#### 4. Update the scheduled date on the jobs

Update all jobs to be scheduled at some point in the future. Remember the date you use... you will need to use this to release the jobs as well.

This may time out if you have a lot of jobs, so you will likely need to update in batches.
```
switch! ‘tenant_name'
batch=10000
jobs = GoodJob::Job.where("serialized_params->>'job_class' = ? AND finished_at IS NULL AND scheduled_at IS NULL AND error IS NULL", 'MigrateResourcesJob').limit(batch)
jobs.update_all(scheduled_at: DateTime.parse("2040-01-01 00:00:00"))
```
Rather than running the batches individually above, you may prefer to use the `find_in_batches` method:
```
batch_size = 10000
scheduled_time = DateTime.parse("2040-01-01 00:00:00")

GoodJob::Job.where("serialized_params->>'job_class' = ? AND finished_at IS NULL AND scheduled_at IS NULL AND error IS NULL", 'MigrateResourcesJob')
            .find_in_batches(batch_size: batch_size) do |batch|
  GoodJob::Job.where(id: batch.map(&:id)).update_all(scheduled_at: scheduled_time)
end
```

#### 5. Restart the workers

Go back to Rancher and start the workers again. You may want to spin up another worker, but when migrating from Fedora, the number of concurrent jobs can be touchy. Monitor the jobs for a while to get a good feel for the appropriate number of jobs.

#### 6. Release a batch of jobs

Using the scheduled date that you assigned previously, select the number of records to be released and reset the scheduled date to nil.
```
batch = 5000
GoodJob::Job.where(scheduled_at: DateTime.parse("2040-01-01 00:00:00")).limit(batch).update_all(scheduled_at: nil)
```
#### 7. Check statistics

You can monitor the processing time by using the job statistics.
```
GoodJob::Job.completed_job_statistics
```
#### 8. Clean out completed jobs

When the database gets too large, it can cause problems. It is good to periodically clear out completed jobs. You may choose to only remove jobs which ended without error in order to retain the errored jobs for follow-up.
```
GoodJob::Job.where("finished_at < ?", 5.days.ago).where(error: nil).find_in_batches(batch_size: 1000) do |batch|
  batch.each do |job|
    job.destroy
  end
end
```
#### 9. Using the Indexing Adapter

For large data migrations, it is helpful to limit the indexing during the process, as each work is indexed multiple times. The `Valkyrie::IndexingAdapter` allows use of a redis queue to collect the indexing jobs and process them in batches.

There is a related error queue to log errors. You can rerun indexing jobs for errored ids.
```
queue = Valkyrie::IndexingAdapter.find(:redis_queue)
bad = queue.list_index_errors.map(&:first)
errors = []
bad.each do |id|
  begin
  resource = Hyrax.query_service.find_by(id: id)
  next unless resource
  Hyrax.index_adapter.save(resource: resource)
  rescue => e
  errors << [id, e]
  end
end
```
#### 10. Check remaining index jobs

At times the index jobs may back up and require additional indexing jobs to help catch up.

Check the number of remaining jobs in the queue:
```
Valkyrie::IndexingAdapter.find(:redis_queue).list_index.size
```
Start additional indexing jobs
```
Hyrax::QueuedIndexingJob.requeue_frequency = 10.seconds (when they requeue after completing)
Hyrax::QueuedIndexingJob.perform_later
```
Indexing jobs respawn themselves, so eventually these jobs need to be killed. The TenantConfigJob will start new jobs if queued indexing is in use and no jobs exist.

#### Verify Results

As data migrates to Valkyrie, they are considered new works (because we are creating them in the Valkyrie database). So in your dashboard, the works will all have new `last_modified` dates showing in the dashboard. 

Works may fail to migrate, and may not throw job errors. One known cause of silent failures is when a model has required metadata that is not included in the work.

#### Bulkrax Considerations

When using `valkyrie_transition` Bulkrax cannot edit or delete works which are not yet migrated.