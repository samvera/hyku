## Description

Fixes #2746 - Inactive controlled vocabulary terms now filtered from dropdown menus when `HYRAX_FLEXIBLE=false`

### Problem
When `HYRAX_FLEXIBLE=false`, inactive controlled vocabulary terms (marked with `active: false` in YAML files like `config/authorities/licenses.yml`) were appearing in dropdown menus on work deposit forms. For example, all 17 licenses were showing instead of just the 8 active ones.

### Solution
Added `select_active_options` methods to all local vocabulary services and updated the form helper to prioritize these methods, which filter out inactive terms while maintaining backward compatibility.

## Changes Made

### Modified Files

1. **`app/helpers/hyrax/form_helper_behavior.rb`**
   - Updated `local_vocabulary_options_for` to call `select_active_options` first (filters inactive terms)
   - Falls back to `select_all_options` or `select_options` for backward compatibility
   - Added inline comments explaining the prioritization logic

2. **`app/services/hyrax/audience_service.rb`**
   - Added `select_active_options` method that filters by `active: true`
   - Maintains existing `select_all_options` for compatibility

3. **`app/services/hyrax/discipline_service.rb`**
   - Added `select_active_options` method

4. **`app/services/hyrax/education_levels_service.rb`**
   - Added `select_active_options` method

5. **`app/services/hyrax/learning_resource_types_service.rb`**
   - Added `select_active_options` method

6. **`app/services/hyrax/oer_types_service.rb`**
   - Added `select_active_options` method

7. **`app/services/hyrax/resource_types_service.rb`** (new file)
   - Created Hyku override of Hyrax's ResourceTypesService
   - Added `select_active_options` method
   - Maintains Hyrax's original `select_options` method

8. **`spec/services/controlled_vocabularies_spec.rb`**
   - Added new describe block "Active Term Filtering (Issue #2746)"
   - Added 3 new test examples verifying the fix
   - All services implement `select_active_options`
   - Filtering works correctly (8 active licenses vs 17 total)
   - Form helper uses `select_active_options` when available

## How It Works

- **New works**: Only active terms appear in dropdown menus
- **Existing works**: Inactive terms that are already selected will still display in edit forms (handled by existing `QaSelectServiceDecorator.include_current_value` method)
- **Backward compatibility**: Services still have `select_all_options` methods for code that may depend on them

## Testing

### Automated Tests
✅ All 22 specs passing in `controlled_vocabularies_spec.rb` (19 existing + 3 new)

### Manual Testing
1. Set `HYRAX_FLEXIBLE=false` in environment
2. Navigate to work deposit form (e.g., `/concern/generic_works/new`)
3. Check License dropdown - should show only 8 active licenses (not all 17)
4. Verify other controlled vocabulary fields (Resource Type, Audience, Discipline, etc.) show only active terms
5. Edit an existing work with an inactive term - the inactive term should still appear with `.force-select` class

### Test Results
```bash
bundle exec rspec [controlled_vocabularies_spec.rb](http://_vscodecontentref_/0)
# 22 examples, 0 failures
```

## Screenshots

_Add screenshots showing before/after of dropdown menus here_

### Before
- License dropdown showing all 17 licenses (including inactive ones)

### After  
- License dropdown showing only 8 active licenses

## Related Issues

Closes #2746

## Checklist

- [x] Tests added/updated
- [x] Documentation updated (inline comments)
- [x] No breaking changes
- [x] Backward compatible
- [ ] Tested manually in browser
- [ ] Screenshots added

## Notes

This fix aligns with how Hyrax's `QaSelectService` is designed to work - it has both `select_all_options` and `select_active_options` methods. The Hyku local vocabulary services were only implementing `select_all_options`, causing inactive terms to appear. Now they implement both methods, allowing the form helper to choose the appropriate one.