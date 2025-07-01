# Controlled Vocabularies in Hyku

Hyku supports both local and remote controlled vocabularies for form fields. You can specify these in your metadata profile YAML files.

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
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - discipline # References config/authorities/discipline.yml
```

This will render as a dropdown select field with options from the discipline vocabulary.

## Remote Controlled Vocabularies

Remote vocabularies query external services and provide autocomplete/typeahead functionality.

### Available Remote Vocabularies

- `loc_subjects` - Library of Congress Subject Headings
- `loc_names` - Library of Congress Name Authority File
- `loc_genre_forms` - Library of Congress Genre/Form Terms
- `geonames` - GeoNames geographical database
- `fast_topics` - OCLC FAST (Faceted Application of Subject Terminology) topics

### Usage in Profile YAML

```yaml
properties:
  subject:
    controlled_values:
      format: http://www.w3.org/2001/XMLSchema#string
      sources:
        - loc_subjects # Library of Congress Subject Headings
```

This will render as an autocomplete field that queries the Library of Congress Subject Headings service as the user types.

## Example Profile Section

```yaml
properties:
  # Local vocabulary - renders as dropdown
  discipline:
    available_on:
      class:
        - OerResource
    controlled_values:
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
      sources:
        - loc_subjects
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
      sources:
        - geonames
    display_label:
      default: Location
    multi_value: true
```

## Adding New Vocabularies

### Adding Local Vocabularies

1. Create a YAML file in `config/authorities/` (e.g., `my_vocabulary.yml`)
2. Add the vocabulary mapping to `controlled_vocabulary_service_for` in `app/helpers/hyrax/form_helper_behavior.rb`
3. Create a corresponding service class following the pattern of existing services

### Adding Remote Vocabularies

1. Ensure the Questioning Authority gem supports the remote service
2. Add the configuration to `remote_authority_config_for` in `app/helpers/hyrax/form_helper_behavior.rb`
3. The URL should follow the QA pattern: `/qa/search/{authority}/{subauthority}`

## How It Works

1. **Profile Import**: When you import a metadata profile, the system reads the `controlled_values.sources`
2. **Form Generation**: The form builder checks if the source maps to a local service or remote authority
3. **Rendering**:
   - Local vocabularies render as `<select>` dropdowns with predefined options
   - Remote authorities render as text inputs with autocomplete functionality
4. **Data Attributes**: Remote authorities get `data-autocomplete` and `data-autocomplete-url` attributes that the JavaScript autocomplete widget uses

The system automatically handles both single and multi-value fields for both local and remote vocabularies.
