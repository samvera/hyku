(function () {
  'use strict';

  var GRID = '[data-featured-grid]';
  var ITEM = '.pr-portfolio';
  var HANDLE = '[data-featured-handle]';
  var MOVE = '[data-featured-move]';
  var STATUS = '[data-featured-status]';
  var UNFEATURE = '[data-featured-unfeature]';

  function items(grid) {
    return Array.prototype.slice.call(grid.querySelectorAll(ITEM));
  }

  function renumber(grid) {
    items(grid).forEach(function (item, index) {
      var field = item.querySelector('input[data-property=order]');
      if (field) field.value = index;
    });
  }
  function dropTarget(grid, dragged, x, y) {
    var over = items(grid).find(function (item) {
      if (item === dragged) return false;
      var box = item.getBoundingClientRect();
      return x >= box.left && x <= box.right && y >= box.top && y <= box.bottom;
    });
    if (!over) return null;

    var box = over.getBoundingClientRect();
    return { item: over, after: x > box.left + box.width / 2 };
  }
  function fill(template, item, list) {
    return template
      .replace('%{title}', function () { return item.dataset.title || ''; })
      .replace('%{position}', function () { return list.indexOf(item) + 1; })
      .replace('%{total}', function () { return list.length; });
  }
  function statusFor(grid) {
    var scope = grid.closest('form') || document;
    return scope.querySelector(STATUS);
  }

  function announce(grid, item, template) {
    var status = statusFor(grid);
    if (!status || !template) return;

    status.textContent = fill(template, item, items(grid));
  }
  function announceUnfeatureFailure(grid) {
    var message = grid.dataset.unfeatureFailed;
    if (!message) return;

    var status = statusFor(grid);
    if (status) status.textContent = message;
    window.alert(message);
  }

  function move(grid, item, delta) {
    var list = items(grid);
    var from = list.indexOf(item);
    var to = from + delta;
    if (to < 0 || to >= list.length) {
      announce(grid, item, grid.dataset.atTemplate);
      return false;
    }

    if (delta > 0) {
      list[to].after(item);
    } else {
      list[to].before(item);
    }
    renumber(grid);
    announce(grid, item, grid.dataset.movedTemplate);
    return true;
  }

  function bindDragging(grid) {
    var dragged = null;
    var from = -1;
    grid.addEventListener('mousedown', function (event) {
      var item = event.target.closest(ITEM);
      if (item) item.draggable = !!event.target.closest(HANDLE);
    });

    grid.addEventListener('dragstart', function (event) {
      dragged = event.target.closest(ITEM);
      if (!dragged) return;
      from = items(grid).indexOf(dragged);
      dragged.classList.add('is-dragging');
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', dragged.dataset.id || '');
    });

    grid.addEventListener('dragover', function (event) {
      if (!dragged) return;
      event.preventDefault();
      event.dataTransfer.dropEffect = 'move';

      var target = dropTarget(grid, dragged, event.clientX, event.clientY);
      if (!target) return;
      if (target.after) {
        target.item.after(dragged);
      } else {
        target.item.before(dragged);
      }
    });

    grid.addEventListener('drop', function (event) {
      if (!dragged) return;
      event.preventDefault();
      renumber(grid);
    });

    grid.addEventListener('dragend', function () {
      if (!dragged) return;
      dragged.classList.remove('is-dragging');
      dragged.draggable = false;
      renumber(grid);
      if (items(grid).indexOf(dragged) !== from) announce(grid, dragged, grid.dataset.movedTemplate);
      dragged = null;
      from = -1;
    });
  }

  function bindButtons(grid) {
    grid.addEventListener('click', function (event) {
      var button = event.target.closest(MOVE);
      if (!button) return;

      event.preventDefault();
      if (move(grid, button.closest(ITEM), Number(button.dataset.featuredMove))) button.focus();
    });
  }

  function bindUnfeature(grid) {
    grid.addEventListener('click', function (event) {
      var link = event.target.closest(UNFEATURE);
      if (!link) return;

      event.preventDefault();
      var item = link.closest(ITEM);
      if (grid.dataset.unfeatureConfirm && !window.confirm(grid.dataset.unfeatureConfirm)) return;

      var token = document.querySelector('meta[name=csrf-token]');

      fetch(link.href, {
        method: 'DELETE',
        credentials: 'same-origin',
        headers: { 'X-CSRF-Token': token ? token.content : '', 'X-Requested-With': 'XMLHttpRequest' }
      }).then(function (response) {
        if (!response.ok) return announceUnfeatureFailure(grid);
        item.remove();
        renumber(grid);
      }).catch(function () {
        announceUnfeatureFailure(grid);
      });
    });
  }

  function bindKeyboard(grid) {
    grid.addEventListener('keydown', function (event) {
      var handle = event.target.closest(HANDLE + ',' + MOVE);
      if (!handle) return;
      var delta = { ArrowUp: -1, ArrowLeft: -1, ArrowDown: 1, ArrowRight: 1 }[event.key];
      if (!delta) return;

      event.preventDefault();
      if (move(grid, handle.closest(ITEM), delta)) handle.focus();
    });
  }

  function start() {
    document.querySelectorAll(GRID).forEach(function (grid) {
      bindDragging(grid);
      bindKeyboard(grid);
      bindButtons(grid);
      bindUnfeature(grid);
      renumber(grid);
    });
  }
  if (window.Turbolinks) {
    document.addEventListener('turbolinks:load', start);
  } else {
    document.addEventListener('DOMContentLoaded', start);
  }
})();
