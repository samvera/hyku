# Migrating from Solr 8 to Solr 9

Solr 8 is [end of life](https://solr.apache.org/downloads.html). Hyku's `solr/conf`
configset works on both Solr 8 and Solr 9, but Solr 8 stays the default everywhere
(new builds, `docker-compose.yml`, `docker-compose.production.yml`) until a dedicated
major-version-bump release switches it.

## Do you need to reindex?

No, for the schema/config changes that made Hyku Solr-9-compatible. They only swap
field *type classes* (e.g. `TrieIntField` → `IntPointField`, `LatLonType` →
`LatLonPointSpatialField`) and add version-conditional `solrconfig.xml` settings -
they don't change how values are stored. Confirmed by reopening a Solr 8.11.2-written
index unreindexed, first under Solr 8 with the new schema and then under Solr 9:
range queries, sorts, and geo queries against the existing documents all returned
correct results.

This is specific to *this* upgrade. A customized `solr/conf`, or a field type change
that genuinely re-encodes existing values, may still require reindexing.

## In development and test

Copy the Solr 9 override file into place, then bring your application up as usual -
Docker Compose merges `docker-compose.override.yml` automatically:

```bash
cp docker-compose.override-solr-9.yml docker-compose.override.yml
docker compose up
```

To switch an *existing* local stack, keep the `solr` volume - no reindex needed -
and just rebuild and restart that one service:

```bash
docker compose build solr
docker compose up -d solr
```

Delete `docker-compose.override.yml` (or `git checkout` it away, since it's
gitignored) to go back to the Solr 8 default.

## In production

`docker-compose.production.yml` stays on Solr 8 by default; `docker-compose.production.override-solr-9.yml`
opts a deployment into Solr 9, applied explicitly since Compose doesn't auto-merge
override files for non-default compose filenames:

```bash
docker compose -f docker-compose.production.yml -f docker-compose.production.override-solr-9.yml up
```

Beyond that, rollout depends on your infrastructure - see Solr's own
[upgrade notes](https://solr.apache.org/guide/solr/latest/upgrade-notes/major-changes-in-solr-9.html).
Choose between a rolling in-place upgrade of existing nodes/volumes, or standing up
new Solr 9 node(s) and cutting over once populated and verified. The no-reindex
result above makes the in-place path realistic, but validate against your own data
and query patterns first.

If you run a customized `solr/conf`, diff yours against the changes in this repo's
[solr/](../solr/) directory history to find what else you may need to change, and check
your Solr 8 logs for deprecation warnings as a starting point.
