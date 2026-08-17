// Shared citation picker: swaps the visible citation and copies it.
// Any theme can opt in with [data-citation] on the wrapper plus
// [data-citation-picker], [data-citation-text], [data-citation-copy] and
// [data-citation-copied] inside it.
(function () {
  'use strict';
  var bound = new WeakSet();

  function showStyle(root, style) {
    root.querySelectorAll('[data-citation-text]').forEach(function (block) {
      block.hidden = block.getAttribute('data-citation-text') !== style;
    });
  }

  function visibleText(root) {
    var shown = root.querySelector('[data-citation-text]:not([hidden])');
    return shown ? shown.textContent.trim() : '';
  }

  function init() {
    document.querySelectorAll('[data-citation]').forEach(function (root) {
      if (bound.has(root)) return;
      bound.add(root);

      var picker = root.querySelector('[data-citation-picker]');
      if (picker) {
        picker.addEventListener('change', function () { showStyle(root, picker.value); });
      }

      var copy = root.querySelector('[data-citation-copy]');
      if (!copy) return;
      if (!navigator.clipboard) {
        copy.hidden = true;
        return;
      }

      var flag = root.querySelector('[data-citation-copied]');
      var timer = null;

      function setCopied(on) {
        if (flag) flag.hidden = !on;
        copy.classList.toggle('is-copied', on);
      }

      function clear() {
        window.clearTimeout(timer);
        timer = null;
      }

      copy.addEventListener('click', function () {
        setCopied(true);
        clear();
        timer = window.setTimeout(function () { setCopied(false); }, 1500);

        navigator.clipboard.writeText(visibleText(root)).catch(function () {
          clear();
          setCopied(false);
        });
      });
    });
  }

  if (window.Turbolinks) {
    document.addEventListener('turbolinks:load', init);
  } else {
    document.addEventListener('DOMContentLoaded', init);
  }
})();
