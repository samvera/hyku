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
  var TOGGLE = '[data-term-status-toggle]';
  var TOGGLE_REASON = '[data-term-status-reason]';
  var DIRTY_NOTE = '[data-term-order-dirty]';
  var CANCEL = '[data-term-order-cancel]';

  function rows(table) {
    return Array.prototype.slice.call(table.querySelectorAll(ROW));
  }

  function sequence(table) {
    return rows(table).map(function (row) {
      return row.dataset.termId;
    }).join(',');
  }

  // Derived by comparing against the order the page loaded with, rather than latched
  // on the first move: a term moved away and back is not an unsaved change, and a
  // page restored from the Turbolinks cache would bring a stale flag with it.
  //
  // Retiring is withheld while the two differ, because that button submits a form of
  // its own and would navigate away from an order recoverable only by redoing it.
  function refreshDirtyState(table) {
    var dirty = sequence(table) !== table.dataset.termOrderLoaded;

    // aria-disabled rather than the attribute, which would drop the button out of the
    // tab order: a keyboard user would find it missing rather than unavailable.
    document.querySelectorAll(TOGGLE).forEach(function (toggle) {
      toggle.classList.toggle('disabled', dirty);
      if (dirty) {
        toggle.setAttribute('aria-disabled', 'true');
      } else {
        toggle.removeAttribute('aria-disabled');
      }

      var reason = toggle.querySelector(TOGGLE_REASON);
      if (reason) reason.classList.toggle('d-none', !dirty);
    });

    var note = document.querySelector(DIRTY_NOTE);
    if (note) note.classList.toggle('d-none', !dirty);

    var cancel = document.querySelector(CANCEL);
    if (cancel) cancel.classList.toggle('d-none', !dirty);
  }

  // Restores the order the table was rendered with, from the same stamp the dirty
  // check compares against.
  function cancelOrder(table) {
    var body = table.querySelector('tbody');
    if (!body) return;

    var byId = {};
    rows(table).forEach(function (row) {
      byId[row.dataset.termId] = row;
    });

    (table.dataset.termOrderLoaded || '').split(',').forEach(function (id) {
      if (byId[id]) body.appendChild(byId[id]);
    });

    refreshDirtyState(table);
  }

  // aria-disabled carries no behavior of its own, so the submit has to be stopped
  // here. Captured on the document because the toggles submit forms of their own,
  // which sit outside the table this script is bound to.
  function refuseDisabledToggles() {
    document.addEventListener('click', function (event) {
      var toggle = event.target.closest(TOGGLE);
      if (!toggle || toggle.getAttribute('aria-disabled') !== 'true') return;

      event.preventDefault();
      event.stopPropagation();
    });
  }

  function statusFor(table) {
    var scope = table.closest('form') || document;
    return scope.querySelector(STATUS);
  }

  // One pass over the template, because a term's label is free text: replacing the
  // placeholders in turn would let a label containing `%{total}` be treated as one.
  function fill(table, template, row, list) {
    var values = {
      label: row.dataset.termLabel || '',
      position: list.indexOf(row) + 1,
      // The vocabulary's size rather than the page's, which a long vocabulary caps.
      total: table.dataset.termTotal || list.length
    };

    return template.replace(/%\{(label|position|total)\}/g, function (match, name) {
      return values[name];
    });
  }

  function announce(table, row, template) {
    var status = statusFor(table);
    if (!status || !template) return;

    status.textContent = fill(table, template, row, rows(table));
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
    refreshDirtyState(table);
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

  // Puts a row back at the index it held before a canceled drag. The row is compared
  // against the list with itself excluded, because its own place in the list would
  // otherwise shift every index after it by one.
  function restore(table, row, index) {
    if (index < 0) return;

    var others = rows(table).filter(function (candidate) {
      return candidate !== row;
    });
    if (!others.length) return;

    if (index >= others.length) {
      others[others.length - 1].after(row);
    } else {
      others[index].before(row);
    }
  }

  // draggable is set on mousedown rather than in the markup, so a drag can only start
  // from the handle. Left on the row, any text selection inside a cell would drag it.
  function bindDragging(table) {
    var dragged = null;
    var from = -1;
    var dropped = false;
    var overRow = false;

    table.addEventListener('mousedown', function (event) {
      var row = event.target.closest(ROW);
      if (row) row.draggable = !!event.target.closest(HANDLE);
    });

    table.addEventListener('dragstart', function (event) {
      dragged = event.target.closest(ROW);
      if (!dragged) return;

      from = rows(table).indexOf(dragged);
      dropped = false;
      overRow = false;
      dragged.classList.add('is-dragging');
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', '');
    });

    table.addEventListener('dragover', function (event) {
      if (!dragged) return;
      event.preventDefault();
      event.dataTransfer.dropEffect = 'move';

      // Latched for the whole drag rather than set per event: the pointer spends the
      // last moments of a drag over the dragged row's own space, which dropTarget
      // skips, so the final dragover of a perfectly good drag reports no target.
      var target = dropTarget(table, dragged, event.clientY);
      if (!target) return;

      overRow = true;

      if (target.after) {
        target.row.after(dragged);
      } else {
        target.row.before(dragged);
      }
    });

    table.addEventListener('drop', function (event) {
      if (!dragged) return;
      event.preventDefault();
      dropped = true;
    });

    // dragend also fires for a drag no drop completed, such as Escape or a release
    // outside the table, which is why the preview is only kept when one did.
    table.addEventListener('dragend', function () {
      if (!dragged) return;

      dragged.classList.remove('is-dragging');
      dragged.draggable = false;

      // A drop that never hovered a row lands on the header or the gap below the
      // table, which is a cancel rather than a move to the last previewed place.
      if (!dropped || !overRow) {
        restore(table, dragged, from);
      } else if (rows(table).indexOf(dragged) !== from) {
        announce(table, dragged, table.dataset.movedTemplate);
      }

      // After either branch: a restored row may have returned the table to its
      // loaded order, and a completed drag may have landed back where it started.
      refreshDirtyState(table);

      dragged = null;
      from = -1;
      dropped = false;
      overRow = false;
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

  // On the form rather than the table, because the button sits below it.
  function bindCancel(table) {
    var scope = table.closest('form');
    if (!scope) return;

    scope.addEventListener('click', function (event) {
      if (!event.target.closest(CANCEL)) return;

      event.preventDefault();
      cancelOrder(table);
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

  // Bound on every turbolinks:load without a guard against binding twice. Restoring
  // a cached page replaces the table with a fresh node, so the listeners attached
  // here go with the old one rather than accumulating on the new one — and a restored
  // page can come back with rows already moved, hence the refresh.
  function start() {
    document.querySelectorAll(TABLE).forEach(function (table) {
      bindDragging(table);
      bindKeyboard(table);
      bindButtons(table);
      bindCancel(table);
      refreshDirtyState(table);
    });
  }

  // Once, not per turbolinks:load: this one is bound to the document, which survives
  // a page change, so re-registering it would stack a handler per visit.
  refuseDisabledToggles();

  if (window.Turbolinks) {
    document.addEventListener('turbolinks:load', start);
  } else {
    document.addEventListener('DOMContentLoaded', start);
  }
})();
