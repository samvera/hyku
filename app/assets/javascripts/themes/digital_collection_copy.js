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
    button.classList.toggle('is-copied', on);
  }

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

  function copy(text, button) {
    if (navigator.clipboard) return navigator.clipboard.writeText(text);
    return selectionCopy(text, button);
  }

  document.addEventListener('click', function (event) {
    var button = event.target.closest('[data-dc-copy-text]');
    if (!button) return;

    window.clearTimeout(timers.get(button));
    show(button, true);
    timers.set(button, window.setTimeout(function () { show(button, false); }, 1500));

    copy(button.getAttribute('data-dc-copy-text'), button).catch(function () {
      window.clearTimeout(timers.get(button));
      show(button, false);
    });
  });
})();
