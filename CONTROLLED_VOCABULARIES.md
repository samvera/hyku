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
- `fast` - OCLC FAST (Faceted Application of Subject Terminology) - topical subjects
- `fast/all` - OCLC FAST - all subjects
- `fast/personal` - OCLC FAST - personal names
- `fast/corporate` - OCLC FAST - corporate names
- `fast/geographic` - OCLC FAST - geographic names
- `mesh` - Medical Subject Headings (MeSH)

**Note**: Authority names use the slash format consistent with Questioning Authority documentation. These match exactly with the configured mappings in the application.

### Discogs (Requires Setup)

Discogs music database authorities are available but require API credentials:

- `discogs/all` - All Discogs types
- `discogs/release` - Music releases
- `discogs/artist` - Artists
- `discogs/label` - Record labels

To enable Discogs authorities:

1. Register for a Discogs developer account at https://www.discogs.com/settings/developers
2. Configure API credentials in your application
3. Uncomment the Discogs authorities in `app/helpers/hyrax/form_helper_behavior.rb`

**Note**: Authority names use the slash format consistent with Questioning Authority documentation. These match exactly with the configured mappings in the application.

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

  # Geographic names with autocomplete
  based_near:
    available_on:
      class:
        - GenericWorkResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - geonames
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

  # Discogs artists
  music_artist:
    available_on:
      class:
        - GenericWorkResource
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - discogs/artist
    display_label:
      default: Music Artist
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
