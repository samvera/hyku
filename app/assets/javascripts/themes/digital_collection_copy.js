(function () {
  'use strict';

  var timers = new WeakMap();

  function status(button) {
    var next = button.nextElementSibling;
    return next && next.matches('[data-dc-copied]') ? next : null;
  }

  function show(button, on) {
    var flag = status(button);
    if (flag) flag.textContent = on ? flag.getAttribute('data-dc-copied') : '';
  }

  document.addEventListener('click', function (event) {
    var button = event.target.closest('[data-dc-copy-text]');
    if (!button) return;

    window.hykuCopyText(button.getAttribute('data-dc-copy-text'), button).then(function () {
      window.clearTimeout(timers.get(button));
      show(button, true);
      timers.set(button, window.setTimeout(function () { show(button, false); }, 1500));
    }, function () {
      window.clearTimeout(timers.get(button));
      show(button, false);
    });
  });
})();
