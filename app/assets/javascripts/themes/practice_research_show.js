(function () {
  'use strict';
  var bound = new WeakSet();

  function showStyle(root, style) {
    root.querySelectorAll('[data-pr-cite-text]').forEach(function (block) {
      block.hidden = block.getAttribute('data-pr-cite-text') !== style;
    });
  }

  function visibleText(root) {
    var shown = root.querySelector('[data-pr-cite-text]:not([hidden])');
    return shown ? shown.textContent.trim() : '';
  }

  function init() {
    document.querySelectorAll('[data-pr-cite]').forEach(function (root) {
      if (bound.has(root)) return;
      bound.add(root);

      var picker = root.querySelector('[data-pr-cite-picker]');
      if (picker) {
        picker.addEventListener('change', function () { showStyle(root, picker.value); });
      }

      var copy = root.querySelector('[data-pr-cite-copy]');
      if (!copy) return;
      if (!navigator.clipboard) {
        copy.hidden = true;
        return;
      }

      var flag = root.querySelector('[data-pr-cite-copied]');
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
