// Shared clipboard copy: resolves once the text is copied, using the selection
// fallback where the browser has no clipboard API.
(function () {
  'use strict';

  function selectionCopy(text, button) {
    var field = document.createElement('textarea');
    field.value = text;
    field.setAttribute('readonly', '');
    field.style.position = 'fixed';
    field.style.opacity = '0';
    document.body.appendChild(field);
    field.select();

    var copied = false;
    try {
      copied = document.execCommand('copy');
    } catch (error) {
      copied = false;
    }

    document.body.removeChild(field);
    button.focus();
    return copied ? Promise.resolve() : Promise.reject();
  }

  window.hykuCopyText = function (text, button) {
    if (navigator.clipboard) return navigator.clipboard.writeText(text);
    return selectionCopy(text, button);
  };
})();
