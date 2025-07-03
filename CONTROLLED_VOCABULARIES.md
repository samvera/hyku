# Controlled Vocabularies in Hyku

Hyku supports both local and remote controlled vocabularies for form fields through the flexible metadata system. When `HYRAX_FLEXIBLE` is enabled, you can specify controlled vocabularies directly in your metadata profile YAML files.

This system is backed by a dynamic database model, allowing vocabularies to be managed on a per-tenant basis without requiring code changes or application restarts.

## How It Works

1.  **Vocabulary Definition**: A list of available controlled vocabularies is stored in the database. A default set can be loaded using a Rake task (see "Managing Vocabularies" below).
2.  **Profile Configuration**: In your metadata profile YAML, you tell a property to use a vocabulary by adding its name to the `controlled_values.sources` array.
3.  **Form Rendering**: When a user edits a work, the form builder looks up the source in the database and renders the correct input type:
    - **Local vocabularies** render as dropdown select fields.
    - **Remote vocabularies** render as autocomplete text inputs.
    - If a source is not found in the database, the field gracefully falls back to a standard text input.

### Configuration Syntax

To make any property use a controlled vocabulary, update its `controlled_values.sources` array in your metadata profile, replacing `"null"` with the name of the desired vocabulary.

```yaml
properties:
  your_property_name:
    # ... other property configuration ...
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - name_of_vocabulary # e.g., "licenses" or "loc/subjects"
```

To specify that a property should NOT use a controlled vocabulary (a free text input), use `"null"`:

```yaml
properties:
  description:
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - "null"
```

## Managing Vocabularies

Controlled vocabularies are now stored in the database and are managed on a per-tenant basis. A default set of vocabularies can be loaded into the system using a Rake task.

### Populating Vocabularies

You can populate the default vocabularies for a single tenant or for all tenants at once. The task uses the tenant's `name` for identification (e.g., 'dev' or 'my-institution').

**To populate a single, specific tenant:**
Provide the tenant's name as an argument.

```bash
bundle exec rails hyrax:controlled_vocabularies:populate['your_tenant_name']
```

**To populate all existing tenants:**
Run the command without any arguments.

```bash
bundle exec rails hyrax:controlled_vocabularies:populate
```

This command is safe to run multiple times and will not create duplicate entries.

### Adding or Customizing Vocabularies

Currently, adding new vocabularies or customizing the existing set must be done through the Rails console. A UI for managing these vocabularies through the admin dashboard is a planned future enhancement.

## Available Vocabularies (via Rake Task)

The following vocabularies are available to be loaded by the `populate` Rake task.

### Local Vocabularies

- `audience`
- `discipline`
- `education_levels`
- `learning_resource_types`
- `oer_types`
- `licenses`
- `resource_types`
- `rights_statements`

### Remote Controlled Vocabularies

- `loc/subjects`, `loc/names`, `loc/genre_forms`, `loc/countries`
- `getty/aat`, `getty/tgn`, `getty/ulan`
- `geonames`
- `fast`, `fast/all`, `fast/personal`, `fast/corporate`, `fast/geographic`
- `mesh`
- `discogs`, `discogs/release`, `discogs/master`

## Third-Party Authority Setup

Some remote authorities require additional setup steps.

### MeSH (Requires Setup)

The Medical Subject Headings (MeSH) vocabulary must be downloaded and imported into the application's database.

1.  **Download the MeSH data file** from the [National Library of Medicine (NLM)](https://www.nlm.nih.gov/databases/download/mesh.html). You will need an ASCII (`.bin`) or XML (`.xml`) file.
2.  **Run the import Rake task**, providing the path to your file:
    ```bash
    RAILS_ENV='production' MESH_FILE=/path/to/mesh.txt bundle exec rake qa:mesh:import
    ```
3.  **Restart the application.**

### Discogs (Requires Setup)

**Setup Instructions:**

1.  Register for a Discogs developer account at `https://www.discogs.com/settings/developers`.
2.  Generate a **Personal Access Token**.
3.  In your Hyku tenant's **Account Settings**, paste your token into the `Discogs user token` field. The application will automatically use this token for API requests.
4.  Generate the discogs formats and genres YAML files by running:
    `bash
    bundle exec rails generate qa:discogs
    `
    As a fallback for development, the application can also use an environment variable (`HYKU_DISCOGS_USER_TOKEN`).

### The `based_near` Property (Location)

The `based_near` property is hardcoded in Hyrax to use the **GeoNames** authority. To make it work, you must include `based_near` in your profile YAML and set up GeoNames integration.

### GeoNames (Requires Setup)

1.  Register for a free GeoNames account at `http://www.geonames.org/manageaccount` and enable web services.
2.  In your Hyku tenant's **Account Settings**, set the `Geonames username` field to your GeoNames username. The application will automatically use this for API requests.
