+function () {
  'use strict';

  function labels() {
    var source = document.querySelector('[data-dc-range-from]');
    return source ? { begin: source.getAttribute('data-dc-range-from'), end: source.getAttribute('data-dc-range-to'),
                      larger: source.getAttribute('data-dc-range-larger'), missing: source.getAttribute('data-dc-range-missing') } : null;
  }

  function labelRangeFields(root, text) {
    Array.prototype.forEach.call(root.querySelectorAll('.range-limit-input-group:not([data-dc-labeled])'), function (group) {
      group.setAttribute('data-dc-labeled', 'true');
      ['begin', 'end'].forEach(function (type) {
        var input = group.querySelector('input.range_' + type);
        var label = input && group.querySelector('label[for="' + input.id + '"]');
        if (!label) return;
        var field = document.createElement('div');
        field.className = 'dc-range-field';
        label.textContent = text[type];
        label.classList.remove('sr-only', 'visually-hidden');
        group.insertBefore(field, input);
        field.appendChild(label);
        field.appendChild(input);
      });
    });
  }

  function relabelLargerLinks(root, text) {
    Array.prototype.forEach.call(root.querySelectorAll('.range_limit .more_facets a, .range_limit .view_larger a'), function (link) {
      link.textContent = text && text.larger ? text.larger : link.textContent.replace(/\s*»\s*$/, '');
    });
  }

  function relabelMissing(root, text) {
    if (!text || !text.missing) return;
    Array.prototype.forEach.call(root.querySelectorAll('.range_limit .facet-values.missing .facet-label a, .range_limit .facet-values.missing .facet-label .selected'), function (label) {
      label.textContent = text.missing;
    });
  }

  function enhance(root) {
    if (!document.body.classList.contains('digital_collection')) return;
    var text = labels();
    if (text) labelRangeFields(root, text);
    relabelLargerLinks(root, text);
    relabelMissing(root, text);
  }

  document.addEventListener('turbolinks:load', function () { enhance(document); });
  document.addEventListener('DOMContentLoaded', function () { enhance(document); });
  document.addEventListener('loaded.blacklight.blacklight-modal', function (event) { enhance(event.target || document); });
  if (window.jQuery) {
    window.jQuery(document).on('loaded.blacklight.blacklight-modal shown.bs.modal', function () { enhance(document); });
  }
}();
