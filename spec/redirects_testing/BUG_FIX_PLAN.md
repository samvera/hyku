# Bug: Redirects form crash in HYRAX_FLEXIBLE=false mode

## Problem

When `HYRAX_FLEXIBLE=false` and `HYRAX_REDIRECTS_ENABLED=true`, editing any work crashes with:

```
NoMethodError: undefined method 'redirects' for an instance of GenericWorkResourceForm
```

**Screenshot:** see `pass1_01_bug_nomethod_redirects_form.png` in this directory.

## Root cause

In `RedirectsFieldBehavior.included` (Hyrax gem at `app/forms/concerns/hyrax/redirects_field_behavior.rb`), only `redirects_attributes` (a virtual property for nested form params) is added to the form class. The actual `redirects` property never reaches the form in non-flexible mode:

- **Flexible mode (works):** `ResourceForm.check_if_flexible` calls `Hyrax::FormFields(model, definition_loader: m3_schema_loader)` which loads all m3 profile properties — including `redirects` — onto the form.
- **Non-flexible mode (crashes):** `check_if_flexible` is never called. The **model** gets `:redirects` via `Hyrax::Schema(:redirects)` at class-load time, but nothing adds `property :redirects` to the **form**. The `redirects_tab?` helper returns `true` (because it checks the model), so the Aliases tab appears. But `_form_redirects.html.erb` line 21 calls `f.object.redirects` on the form object, which doesn't have it.

Key code locations in the Hyrax gem:
- `app/forms/concerns/hyrax/redirects_field_behavior.rb:31-37` — `self.included` only adds `redirects_attributes`
- `app/forms/hyrax/forms/resource_form.rb:126-129` — `check_if_flexible` only runs in flexible mode
- `app/views/hyrax/base/_form_redirects.html.erb:21` — calls `f.object.redirects` (crashes)

## Recommended fix

### Option A: Hyku-side decorator (temporary workaround)

Create `app/forms/hyrax/forms/resource_form_decorator.rb`:

```ruby
# frozen_string_literal: true

# OVERRIDE Hyrax — In non-flexible mode, RedirectsFieldBehavior adds
# redirects_attributes (virtual) to the form but not redirects itself.
# The form partial _form_redirects.html.erb needs f.object.redirects.
# Add the missing property when redirects_enabled? is true.
#
# In flexible mode this is a no-op because the m3 loader already
# defined the property. The `unless` guard prevents double-definition.
if Hyrax.config.redirects_enabled?
  unless Hyrax::Forms::ResourceForm.properties.key?('redirects')
    Hyrax::Forms::ResourceForm.property :redirects,
                                         default: [],
                                         type: Valkyrie::Types::Array.of(Dry::Types['hash'])
  end
end
```

### Option B: Upstream Hyrax fix (proper long-term fix)

Modify `RedirectsFieldBehavior.included` in Hyrax to also add `property :redirects`:

```ruby
# In app/forms/concerns/hyrax/redirects_field_behavior.rb
def self.included(descendant)
  return unless Hyrax.config.redirects_enabled?
  descendant.property :redirects_attributes,
                      virtual: true,
                      populator: :redirects_attributes_populator,
                      prepopulator: :redirects_attributes_prepopulator
  # Add the redirects property itself so the form partial can read it.
  # In flexible mode the m3 loader already defined this; the guard
  # prevents double-definition.
  unless descendant.properties.key?('redirects')
    descendant.property :redirects,
                        default: [],
                        type: Valkyrie::Types::Array.of(Dry::Types['hash'])
  end
end
```

## Failing spec

A failing spec already exists at `spec/forms/redirects_form_property_spec.rb` on the `test/redirects-specs` branch. It verifies:

1. Model has `:redirects` — PASS
2. Form has `:redirects_attributes` — PASS
3. Form has `:redirects` — **FAIL** (this is the bug)

## Verification after fix

1. `bundle exec rspec spec/forms/redirects_form_property_spec.rb` — all 3 examples should pass
2. `bundle exec rspec spec/requests/redirects/ spec/lib/hyrax/transactions/ spec/views/hyrax/dashboard/collections/` — all 33 examples should still pass
3. With `HYRAX_FLEXIBLE=false`: navigate to work edit page, click Aliases tab — should render without error
4. With `HYRAX_FLEXIBLE=true`: same test — should still work (no regression)
