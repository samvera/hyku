# Controlled Vocabularies in Hyku

Hyku supports both local and remote controlled vocabularies for form fields through the flexible metadata system. When `HYRAX_FLEXIBLE` is enabled, you can specify controlled vocabularies directly in your metadata profile YAML files by configuring the `controlled_values.sources` array for any property.

## How It Works

The flexible metadata system automatically detects controlled vocabularies based on the `sources` configuration:

1. **Profile Import**: When you import a metadata profile, the system reads the `controlled_values.sources` array
2. **Form Generation**: The form builder checks if the source is a local authority file or remote authority service
3. **Rendering**:
   - Local vocabularies render as dropdown select fields with predefined options
   - Remote authorities render as autocomplete text inputs that query external services
4. **Data Attributes**: Remote authorities get `data-autocomplete` and `data-autocomplete-url` attributes for JavaScript functionality

## Configuration Syntax

To make any property use a controlled vocabulary, update its `controlled_values.sources` array in your metadata profile:

```yaml
properties:
  your_property:
    # ... other property configuration ...
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - authority_name # Instead of ["null"]
```

## Local Controlled Vocabularies

Local vocabularies are stored as YAML files in `config/authorities/` and provide dropdown select options.

### Available Local Vocabularies

- `audience` - Target audiences for educational resources
- `discipline` - Academic disciplines and subject areas
- `education_levels` - Educational levels (K-12, undergraduate, etc.)
- `learning_resource_types` - Types of educational resources
- `oer_types` - Open Educational Resource types
- `licenses` - Creative Commons and other license options for the work
- `resource_types` - Types of resources, such as "Article" or "Image"
- `rights_statements` - Rights statements indicating the copyright status of the work

### Usage in Profile YAML

```yaml
properties:
  discipline:
    available_on:
      class:
        - OerResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - discipline # References config/authorities/discipline.yml
    display_label:
      default: Discipline
    form:
      required: true
      primary: true
    multi_value: true
```

This will render as a dropdown select field with options from the discipline vocabulary file.

## Remote Controlled Vocabularies

Remote vocabularies query external services through the Questioning Authority gem and provide autocomplete/typeahead functionality.

### Available Remote Vocabularies

- `loc/subjects` - Library of Congress Subject Headings
- `loc/names` - Library of Congress Name Authority File
- `loc/genre_forms` - Library of Congress Genre/Form Terms
- `loc/countries` - Library of Congress Countries
- `getty/aat` - Getty Art & Architecture Thesaurus
- `getty/tgn` - Getty Thesaurus of Geographic Names
- `getty/ulan` - Getty Union List of Artist Names
- `geonames` - GeoNames geographical database
- `fast` - OCLC FAST (Faceted Application of Subject Terminology) – topical subjects
- `fast/all` - OCLC FAST – all subjects
- `fast/personal` - OCLC FAST – personal names
- `fast/corporate` - OCLC FAST – corporate names
- `fast/geographic` - OCLC FAST – geographic names
- `mesh` - Medical Subject Headings (MeSH)
- `discogs` - All Discogs types
- `discogs/release` - Music releases
- `discogs/master` - Master releases

**Note**: Authority names use the slash format consistent with Questioning Authority documentation. These match exactly with the configured mappings in the application.

### MeSH (Requires Setup)

> **Note:**
> Using the MeSH controlled vocabulary requires a one-time setup by a developer to download and import the data. The MeSH vocabulary is not queried live from an external source; instead, it is loaded into the application's database from a data file.

To set up the MeSH vocabulary:

1.  **Download the MeSH data file.** The required file can be obtained from the [National Library of Medicine (NLM)](https://www.nlm.nih.gov/databases/download/mesh.html). You will need to download one of the ASCII (`.bin`) or XML (`.xml`) formats and convert it to a plain text file where each line is a single term. For example, if you download `d2023.bin`, you may need to process it to extract just the MeSH Headings (`MH` fields).

2.  **Run the import Rake task.** Place the processed text file in a location accessible to your application. Then, from your application's root directory, run the following command, replacing `path/to/mesh.txt` with the actual path to your file:

    ```bash
    RAILS_ENV='production' MESH_FILE=path/to/mesh.txt bundle exec rake qa:mesh:import
    ```

3.  **Restart the application.** After the import is complete, restart your Hyku application for the MeSH vocabulary to be available.

Once set up, you can use `mesh` as a source in your metadata profiles, and it will provide an autocomplete search against the imported terms.

### Discogs (Requires Setup)

> **Note:**  
> Discogs integration in Hyku requires a Personal Access Token from your Discogs account. The Questioning Authority gem's OAuth implementation is outdated for new Discogs applications.

Discogs music database authorities are available with proper setup:

- `discogs` - All Discogs types
- `discogs/release` - Music releases
- `discogs/master` - Master releases

**Setup Instructions:**

1. Register for a Discogs developer account at https://www.discogs.com/settings/developers
2. Generate a **Personal Access Token** (not an OAuth application).
3. Generate the discogs formats and genres YAML files by running the following command:
   ```
   RAILS_ENV=production rails generate qa:discogs
   bundle exec rails generate qa:discogs
   ```
4. In your Hyku tenant's Account Settings, set the `Discogs user token` field to your Personal Access Token.

The integration is automatically enabled when the `Discogs user token` is set and both `discogs-formats.yml` and `discogs-genres.yml` are present in your application's `config/` directory.

**What works:**

- Music release autocomplete (searches release titles, not artist names)
- Master release autocomplete
- Search terms like "Abbey Road", "Live", "Greatest Hits" work well

**What doesn't work:**

- Artist and label authorities (not supported by current QA gem version)
- OAuth Consumer Key/Secret authentication (deprecated for new apps)

### The `based_near` Property (Location)

The `based_near` property has special handling in Hyrax. It must be included in your metadata profile to appear on forms, but its controlled vocabulary behavior is hardcoded in Hyrax to use GeoNames via a specific view partial (`app/views/records/edit_fields/_based_near.html.erb`).

This means:

- You should include `based_near` in your profile YAML to make it appear on the form.
- The field will always render with autocomplete functionality using the **GeoNames** authority, regardless of the `sources` configuration in the profile. You can set `sources: ["null"]`.
- For the autocomplete to work, you must set up GeoNames integration as described in the next section.

### GeoNames (Requires Setup)

GeoNames geographical database integration requires a free username:

**Setup Instructions:**

1. Register for a free GeoNames account at http://www.geonames.org/manageaccount
2. Enable web services for your account (this may take up to an hour after registration)
3. In your Hyku tenant's Account Settings, set the `Geonames username` field to your GeoNames username
4. The integration will automatically use your username for API requests

**What it provides:**

- Geographical place name autocomplete
- Global coverage of cities, countries, regions, and landmarks
- Standardized geographic authority data

### Usage in Profile YAML

```yaml
properties:
  subject:
    available_on:
      class:
        - GenericWorkResource
        - OerResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - loc/subjects # Library of Congress Subject Headings
    display_label:
      default: Subject
    form:
      primary: false
    multi_value: true
```

This will render as an autocomplete field that queries the Library of Congress Subject Headings service as the user types.

## Complete Example Profile Section

```yaml
properties:
  # Local vocabulary - renders as dropdown
  discipline:
    available_on:
      class:
        - OerResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - discipline
    display_label:
      default: Discipline
    form:
      required: true
      primary: true
    multi_value: true

  # Remote vocabulary - renders as autocomplete
  subject:
    available_on:
      class:
        - GenericWorkResource
        - OerResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - loc/subjects
    display_label:
      default: Subject
    form:
      primary: false
    multi_value: true

  # Geographic names with autocomplete.
  # The `based_near` field has special handling in Hyrax. See the note above.
  based_near:
    available_on:
      class:
        - GenericWorkResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - "null"
    display_label:
      default: Location
    multi_value: true

  # Medical subjects
  medical_subject:
    available_on:
      class:
        - GenericWorkResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - mesh
    display_label:
      default: Medical Subject
    multi_value: true

  # Art & Architecture terms
  art_subject:
    available_on:
      class:
        - ImageResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - getty/aat
    display_label:
      default: Art Subject
    multi_value: true

  # FAST topics
  fast_subject:
    available_on:
      class:
        - GenericWorkResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - fast
    display_label:
      default: FAST Subject
    multi_value: true

  # FAST geographic names
  fast_geographic:
    available_on:
      class:
        - GenericWorkResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - fast/geographic
    display_label:
      default: Geographic Subject
    multi_value: true

  # Discogs music releases
  music_release:
    available_on:
      class:
        - GenericWorkResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - discogs/release
    display_label:
      default: Music Release
    multi_value: true
```

## No Controlled Vocabulary (Default)

To specify that a property should NOT use controlled vocabulary (free text input), use:

```yaml
properties:
  description:
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - "null" # No controlled vocabulary
```

## Managing Local Vocabularies

### Current Method

Local authority files are managed by editing the YAML files directly in `config/authorities/`. After making changes, restart the application for changes to take effect.

### File Structure

```yaml
# config/authorities/discipline.yml
terms:
  - id: "Mathematics"
    term: "Mathematics"
  - id: "Biology"
    term: "Biology"
```

### Future Enhancement

A UI for managing local vocabularies through the admin dashboard is planned to make vocabulary management more user-friendly for repository administrators.

## Adding New Vocabularies

### Adding Local Vocabularies

1. Create a YAML file in `config/authorities/` following the existing pattern
2. Reference the file name (without .yml extension) in your metadata profile's `sources` array
3. Restart the application

### Adding Remote Vocabularies

1. Ensure the Questioning Authority gem supports the remote service
2. Add the authority mapping to the `remote_authority_config_for` method in `app/helpers/hyrax/form_helper_behavior.rb`
3. Use the authority name in your metadata profile's `sources` array

## Technical Implementation

The flexible metadata system processes controlled vocabularies as follows:

1. **Profile Processing**: `Hyrax::FlexibleSchema` reads the `controlled_values.sources` from the YAML profile
2. **Form Rendering**: The form metadata partial checks each property's configuration
3. **Dynamic Rendering**: Properties with `sources` other than `["null"]` are rendered as controlled vocabulary fields
4. **Authority URLs**: Remote authorities automatically get the correct autocomplete URL pattern

This system automatically handles both single and multi-value fields for both local and remote vocabularies, providing a seamless experience for repository administrators and depositors.
