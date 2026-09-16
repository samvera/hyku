# Migrating from Solr 8 to Solr 9

Solr 8 is [end of life](https://solr.apache.org/downloads.html); Hyku's `solr/conf`
configset is compatible with both Solr 8 and Solr 9, but **Solr 8 is still the
default** everywhere (new builds, `docker-compose.yml`, `docker-compose.production.yml`)
until a separate, explicit major-version-bump release switches it.

## Do you need to reindex?

No, for the schema/config changes that made Hyku Solr-9-compatible specifically.
Those changes only swap field *type classes* (e.g. `TrieIntField` → `IntPointField`,
`LatLonType` → `LatLonPointSpatialField`) and add version-conditional `solrconfig.xml`
settings - they don't change how a document's values are stored. This was verified
directly, not assumed: an index written by Solr 8.11.2 was reopened, unreindexed,
first under Solr 8 with the new schema and then under Solr 9 itself, and range
queries, sorts, and geo queries against the existing documents all returned correct
results in both cases.

This guarantee is specific to *this* upgrade. If you've customized your own
`solr/conf` beyond what's in this repo, or if you change a field's type to something
that genuinely re-encodes existing values, reindexing may still apply to that change.

## In development and test

Copy the Solr 9 override file into place, then bring your application up as usual -
Docker Compose merges `docker-compose.override.yml` automatically:

```bash
cp docker-compose.override-solr-9.yml docker-compose.override.yml
docker compose up
```

To switch an *existing* local stack from Solr 8 to Solr 9, since reindexing isn't
required you can keep the `solr` volume - just rebuild and restart that one service:

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

Beyond that, how you actually roll this out depends on your infrastructure - Solr's own
[Solr 9 upgrade notes](https://solr.apache.org/guide/solr/latest/upgrade-notes/major-changes-in-solr-9.html)
are worth reading before you plan a production migration. You'll want to decide between
a rolling in-place upgrade of your existing Solr nodes/volumes, or standing up new Solr 9
node(s) and cutting over traffic once they're populated and verified - the "no reindex
needed" result above makes the in-place path realistic, but validate it against your own
data and query patterns before trusting it in production.

If you run a customized `solr/conf`, diff yours against the changes in this repo's
[solr/](../solr/) directory history to find what else you may need to change, and check
your Solr 8 logs for deprecation warnings as a starting point.
