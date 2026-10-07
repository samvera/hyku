# OAI-PMH

Hyku serves OAI-PMH from `/catalog/oai` on each tenant. Its records are the ones the catalog search returns to whoever is asking, so a harvester gets the public works and collections the catalog lists, and a signed-in user also gets what they can read.

## Metadata formats

| Prefix | Built from | Switched on by |
| --- | --- | --- |
| `oai_dc` | each property's `simple_dc_pmh` mapping | always on |
| `oai_hyku` | a fixed field list in `lib/oai/provider/metadata_format/hyku_dublin_core.rb` | always on |
| `mods` | each property's `mods_oai_pmh` mapping | the **OAI-PMH MODS** feature (`oai_mods`) at `/admin/features`, off by default |

## Where mappings come from

A format built from a mappings key reads each property's mapping under that key, from the same place for every key:

- **With `HYRAX_FLEXIBLE` enabled**, from the tenant's metadata profile:

  ```yaml
  properties:
    date_created:
      mappings:
        mods_oai_pmh: mods:originInfo/mods:dateCreated
        simple_dc_pmh: dc:date
  ```

  Mapping changes apply to every record as soon as a new profile version is saved, including records created under an earlier version; no re-saving or reindex is needed unless the new version also changes what a property indexes.

- **Without `HYRAX_FLEXIBLE` enabled**, from the schema files under `config/metadata/`, in each attribute's `mappings` block.

A property with no mapping under the key is left out of that format, except title, which each format includes regardless.

## MODS

The `mods` prefix serves [MODS 3.7](https://www.loc.gov/standards/mods/) records. A tenant whose metadata profile maps no property under `mods_oai_pmh` does not offer it, even with the feature on.

Values come from the property's index fields, preferring its `_tesim` field. Title is always included, as `mods:titleInfo/mods:title`, unless a mapping for `title` says otherwise.

Hyku's default metadata profile and its metadata YAML map the common properties (titles, names with their roles, dates, publisher, subjects, places, language, genre, rights, identifiers and so on) to the same MODS elements in both modes. A tenant whose profile predates these mappings gets them by saving a new profile version that includes them.

### Writing a MODS mapping

A mapping is a small subset of XPath describing where a value goes. Every step needs the `mods:` prefix.

| Form | Example | Output for the value `X` |
| --- | --- | --- |
| Nested elements | `mods:originInfo/mods:dateCreated` | `<originInfo><dateCreated>X</dateCreated></originInfo>` |
| Attributes | `mods:identifier[@type="local"]` | `<identifier type="local">X</identifier>` |
| A fixed child element | `mods:name[mods:role/mods:roleTerm="creator"]/mods:namePart` | `<name><role><roleTerm>creator</roleTerm></role><namePart>X</namePart></name>` |

Predicates can be combined (`mods:relatedItem[@type="host"][@displayLabel="Collection"]/mods:titleInfo/mods:title`), and either quote style works. Anything else, such as `contains()` or a step without `mods:`, is not supported: the property is left out of MODS records and a warning naming the mapping is logged. So is a mapping the MODS 3.7 schema does not allow, such as an element placed where MODS has no such child, or an attribute or attribute value MODS does not define; what a value itself may hold is not checked, since it depends on the data. Saving a profile shows a warning for each such mapping.

### How MODS values are grouped

- Properties mapped beneath the same wrapper element, with the same attributes, share one instance of it. `date_created` and `publisher`, mapped to `mods:originInfo/mods:dateCreated` and `mods:originInfo/mods:publisher`, produce a single `originInfo`.
- `name`, `titleInfo`, `relatedItem`, `subject`, `language` and `place` are the exception: each value gets its own, because each describes a different person, title, related resource, subject heading, language or place. Two keywords produce two `subject` elements rather than one compound heading.
- A value that is a URI with a label in the index (a controlled vocabulary term) is written as its label, and keeps the URI as `valueURI`, or `xlink:href` on `accessCondition`, where MODS allows one.

Every record also carries a `location` with the work's page (`url usage="primary"`) and, when it has a thumbnail of its own rather than a placeholder or the tenant's default image, that thumbnail (`url access="preview"`), and a `recordInfo` with its identifier and creation and change dates.

Records are written with their top-level elements in the conventional order of the MODS outline (`titleInfo`, `name`, `genre`, `originInfo` and so on, ending with `recordInfo`), whatever order the profile lists its properties in.

## Adding a format built from a mappings key

Each piece of a mapped format has one home. MODS is the worked example.

| Piece | Where | MODS |
| --- | --- | --- |
| The mappings key | declared under the profile's top-level `mappings:`, then set on each property in the profile and in the `config/metadata/*.yaml` attributes | `Hyku::Mods::MAPPING_KEY` |
| Keeping profile and YAML identical | add the key to the list in `spec/config/oai_mappings_spec.rb` | listed |
| The record's mapped properties, in either mode | `SolrDocument#schema_data_for(key)` | called by `SolrDocument#to_mods` |
| Reading their values: index field, controlled-value labels, shared index fields, the title fallback | `Hyku::OaiPmh::MappedValues` | used by `Hyku::Mods::RecordBuilder` |
| Writing the format's XML | a builder under `app/services/hyku/<format>/`, called from `SolrDocument#to_<prefix>` | `app/services/hyku/mods/` |
| Registering the prefix | a format class under `lib/oai/provider/metadata_format/`, passed to `OAI::Provider::Base.register_format` | `Oai::Provider::MetadataFormat::Mods` |
| Switching it on per tenant | include `Hyku::OaiPmh::MappedFormat` in the format class and define `feature` and `mapping_key`; declare the feature in `config/features.rb` | `oai_mods` |
| Warning about unusable mappings when a profile is saved | a validator under `app/services/hyku/flexible_schema_validators/`, added to `flexible_schema_validators` in `config/initializers/hyrax.rb`, with messages in `config/locales/hyrax.*.yml` | `ModsMappingValidator` |
