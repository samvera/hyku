# Issue #2641 - Add Remove Button for Default Admin Set

**GitHub Issue:** https://github.com/samvera/hyku/issues/2641  
**Branch:** `2641-add-remove-button-default-admin-set`  
**Status:** Investigation in progress - paused to address issue #2746  
**Date:** November 6, 2025

## Problem Statement
Add a "Remove" button for the default Admin Set in collection type participants management, similar to how it works for the Repository Administrators group. The button should be disabled to prevent accidental removal.

## Current Implementation Analysis

### Repository Administrators Pattern (Reference)
- **Location:** `app/views/hyrax/admin/collection_types/_form_participant_table.html.erb` (lines 24-29)
- **Logic:** 
  ```erb
  <% if g.admin_group? && g.access == Hyrax::CollectionTypeParticipant::MANAGE_ACCESS %>
    <%= link_to t("helpers.action.remove"), hyrax.admin_collection_type_participant_path(g), 
        method: :delete, class: 'btn btn-sm btn-danger disabled', disabled: true %>
  <% else %>
    <%= link_to t("helpers.action.remove"), hyrax.admin_collection_type_participant_path(g), 
        method: :delete, class: 'btn btn-sm btn-danger' %>
  <% end %>