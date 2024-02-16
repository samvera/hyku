# Hyku Specs

As an application that mounts the Hyrax Rails engine, Hyku's test suite is a bit different.  We rely on the Hyrax specs for baseline behavior, and in cases where we change that behavior, we write tests in Hyku.

## Hyku Factories

In an effort to reduce duplication and preventing drift, Hyku 6 is working to remove out-dated factories.  This is done by:

- Removing factories that duplicated Hyrax.
- Explicitly requiring all of Hyrax's factories.
- Inheriting and/or modifying factories in Hyku that were defined in Hyrax.

`FactoryBot` supports both [inheritance](https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md#inheritance) and [modification](https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md#modifying-factories)

In the case where you are unable to make changes to the factory through *inheritance* or *modification*, you can remove the corresponding require for the factory.

The `./regenerate_factories_from_hyrax.rb` script provided the initial stubbing of the Hyrax factories and is envisioned as a tool that might help with resynchronization.

### FactoryBot Strategies

In addition to the baseline `FactoryBot.build` and `FactoryBot.create` Hyrax provides:

- `FactoryBot.create_valkyrie` :: For creating a Valkyrie-only object, that is never writing the object via ActiveFedora.
- `FactoryBot.json` :: For creating a JSON object; a read of the Hyrax specs shows that this strategy is used as part of other factories.

### AdminSet and PermissionTemplate

The default Permission Template for Hyku is a bit more complicated than Hyrax.  When you want a properly created factory of permission template and admin set use the following:

```ruby
let(:permission_template) { FactoryBot.create(:permission_template, with_admin_set: true, source_id: admin_set.id) }
let(:admin_set) { FactoryBot.valkyrie_create(:hyku_admin_set) }
```
