// Drag-and-drop sequencing for a vocabulary's terms.
//
// The order is carried by the sequence of the `term_ids[]` fields, not by a number
// written into them: a browser submits fields in document order, so moving the row
// moves its field and there is nothing to keep in step. The server renumbers from
// the order it receives.
//
// The arrow keys and the move buttons exist because dragging is unavailable to a
// keyboard, a screen reader, and a touch device; every move is announced for the
// same reason.
(function () {
  'use strict';

  var TABLE = '[data-term-order-table]';
  var ROW = '[data-term-row]';
  var HANDLE = '[data-term-handle]';
  var MOVE = '[data-term-move]';
  var STATUS = '[data-term-order-status]';

  function rows(table) {
    return Array.prototype.slice.call(table.querySelectorAll(ROW));
  }

  function statusFor(table) {
    var scope = table.closest('form') || document;
    return scope.querySelector(STATUS);
  }

  // One pass over the template, because a term's label is free text: replacing the
  // placeholders in turn would let a label containing `%{total}` be treated as one.
  function fill(template, row, list) {
    var values = {
      label: row.dataset.termLabel || '',
      position: list.indexOf(row) + 1,
      total: list.length
    };

    return template.replace(/%\{(label|position|total)\}/g, function (match, name) {
      return values[name];
    });
  }

  function announce(table, row, template) {
    var status = statusFor(table);
    if (!status || !template) return;

    status.textContent = fill(template, row, rows(table));
  }

  // A row already at the end announces that rather than failing silently, which on a
  // keyboard is the only signal that the key was received.
  function move(table, row, delta) {
    var list = rows(table);
    var from = list.indexOf(row);
    var to = from + delta;

    if (to < 0 || to >= list.length) {
      announce(table, row, table.dataset.atTemplate);
      return false;
    }

    if (delta > 0) {
      list[to].after(row);
    } else {
      list[to].before(row);
    }
    announce(table, row, table.dataset.movedTemplate);
    return true;
  }

  // The row the pointer is over, and which side of its midpoint — a tall row would
  // otherwise flip as soon as the pointer entered it.
  function dropTarget(table, dragged, y) {
    var over = rows(table).find(function (row) {
      if (row === dragged) return false;
      var box = row.getBoundingClientRect();
      return y >= box.top && y <= box.bottom;
    });
    if (!over) return null;

    var box = over.getBoundingClientRect();
    return { row: over, after: y > box.top + box.height / 2 };
  }

  // draggable is set on mousedown rather than in the markup, so a drag can only start
  // from the handle. Left on the row, any text selection inside a cell would drag it.
  function bindDragging(table) {
    var dragged = null;
    var from = -1;

    table.addEventListener('mousedown', function (event) {
      var row = event.target.closest(ROW);
      if (row) row.draggable = !!event.target.closest(HANDLE);
    });

    table.addEventListener('dragstart', function (event) {
      dragged = event.target.closest(ROW);
      if (!dragged) return;

      from = rows(table).indexOf(dragged);
      dragged.classList.add('is-dragging');
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', '');
    });

    table.addEventListener('dragover', function (event) {
      if (!dragged) return;
      event.preventDefault();
      event.dataTransfer.dropEffect = 'move';

      var target = dropTarget(table, dragged, event.clientY);
      if (!target) return;

      if (target.after) {
        target.row.after(dragged);
      } else {
        target.row.before(dragged);
      }
    });

    table.addEventListener('drop', function (event) {
      if (dragged) event.preventDefault();
    });

    table.addEventListener('dragend', function () {
      if (!dragged) return;

      dragged.classList.remove('is-dragging');
      dragged.draggable = false;
      if (rows(table).indexOf(dragged) !== from) {
        announce(table, dragged, table.dataset.movedTemplate);
      }
      dragged = null;
      from = -1;
    });
  }

  function bindButtons(table) {
    table.addEventListener('click', function (event) {
      var button = event.target.closest(MOVE);
      if (!button) return;

      event.preventDefault();
      // Refocused because the button moved with its row, and the browser drops focus
      // on an element it re-parents.
      if (move(table, button.closest(ROW), Number(button.dataset.termMove))) button.focus();
    });
  }

  function bindKeyboard(table) {
    table.addEventListener('keydown', function (event) {
      var control = event.target.closest(HANDLE + ',' + MOVE);
      if (!control) return;

      var delta = { ArrowUp: -1, ArrowDown: 1 }[event.key];
      if (!delta) return;

      event.preventDefault();
      if (move(table, control.closest(ROW), delta)) control.focus();
    });
  }

  function start() {
    document.querySelectorAll(TABLE).forEach(function (table) {
      bindDragging(table);
      bindKeyboard(table);
      bindButtons(table);
    });
  }

  if (window.Turbolinks) {
    document.addEventListener('turbolinks:load', start);
  } else {
    document.addEventListener('DOMContentLoaded', start);
  }
})();
