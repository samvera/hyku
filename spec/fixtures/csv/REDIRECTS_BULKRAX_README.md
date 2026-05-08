# Bulkrax CSV Import for Redirects

These CSVs test creating and updating works/collections with redirect aliases via Bulkrax.

## Required field mapping

Bulkrax needs to know how to assemble the `redirects` hash from CSV columns. Before importing, add these field mappings to the tenant's Bulkrax configuration (via Account settings or the importer's field mapping):

```ruby
'path' => { from: ['redirects_path'], object: 'redirects' },
'canonical' => { from: ['redirects_canonical'], object: 'redirects' },
'sequence' => { from: ['redirects_sequence'], object: 'redirects' }
```

This tells Bulkrax that columns named `redirects_path_1`, `redirects_canonical_1`, `redirects_path_2`, etc. should be assembled into an array of hashes:

```ruby
[
  { 'path' => '/legacy/dspace/handle/12345', 'canonical' => 'true', 'sequence' => '0' },
  { 'path' => '/old-catalog/item-99', 'canonical' => 'false', 'sequence' => '1' }
]
```

The numeric suffix (`_1`, `_2`) distinguishes multiple redirect entries on one record.

## CSV files

### `redirects_new_work.csv`
Creates a new GenericWorkResource with two redirect aliases.

| Column | Value | Purpose |
|--------|-------|---------|
| `source_identifier` | `redirect-test-001` | Bulkrax source ID |
| `model` | `GenericWorkResource` | Work type |
| `title` | `Redirects Import Test` | Required field |
| `creator` | `Test Author` | Required field |
| `rights_statement` | `http://rightsstatements.org/vocab/InC/1.0/` | Required field |
| `visibility` | `open` | Public visibility |
| `redirects_path_1` | `/legacy/dspace/handle/12345` | First redirect path |
| `redirects_canonical_1` | `true` | Mark as canonical |
| `redirects_path_2` | `/old-catalog/item-99` | Second redirect path |
| `redirects_canonical_2` | `false` | Not canonical |

### `redirects_update_existing.csv`
Updates the existing "cat" work (`8fc66f72-cf17-41a9-9fdb-8c42b468239c`) to replace its redirects with new ones.

**Important:** When updating, set the importer's source identifier to `id` (not `source_identifier`) so Bulkrax matches on the work's Valkyrie ID. Or use the work's `bulkrax_identifier` if it has one.

| Column | Value | Purpose |
|--------|-------|---------|
| `source_identifier` | `8fc66f72-cf17-41a9-9fdb-8c42b468239c` | Existing work ID |
| `model` | `GenericWorkResource` | Work type |
| `title` | `cat` | Keep existing title |
| `redirects_path_1` | `/old-site/cats/maine-coon` | New redirect path |
| `redirects_canonical_1` | `true` | Canonical |
| `redirects_path_2` | `/archive/2024/feline-study` | Second path |
| `redirects_canonical_2` | `false` | Not canonical |

### `redirects_collection.csv`
Creates a new CollectionResource with one redirect alias.

## How to import

1. Go to `/importers/new` on the tenant
2. Choose "CSV - Comma Separated Values"
3. Upload the CSV file
4. Set the field mappings (see above) or ensure they're in the tenant's Account settings
5. For updates: set "Source identifier" field to `id` and check "Update existing records"
6. Submit the import

## Verifying the import

After import completes:
- Edit the work/collection, click the Aliases tab — redirect entries should appear
- `curl -I https://<tenant>/legacy/dspace/handle/12345` — should return 301
- Check the ledger: `Hyrax::RedirectPath.where(resource_id: '<id>')` should show rows

## Prerequisites

- `HYRAX_REDIRECTS_ENABLED=true`
- FlipFlop `redirects` enabled for the tenant
- `HYRAX_FLEXIBLE=true` (the form bug in `HYRAX_FLEXIBLE=false` mode will prevent the Aliases tab from rendering, but the data will still be persisted and the resolver will work)
