// Browse collections on the digital collection home page. The server renders
// every public collection once; this sorts, pages and switches the layout in
// place, so the cards re-lay-out under a fixed heading with no navigation.
// State is view, sort and page, stored in the URL fragment so no browse state
// ever reaches the query string or the server. Sort resets the page, view does
// not, and the page is clamped on every render. Labels come from the section's
// data attributes so the markup stays the only source of copy.
+function () {
  'use strict';

  var KEYS = { view: 'view', sort: 'sort', page: 'page' };
  var DEFAULTS = { view: 'grid', sort: 'asc', page: '1' };
  var STORAGE = 'dc:collections_view';


  function remembered() {
    try { return localStorage.getItem(STORAGE); } catch (e) { return null; }
  }

  function remember(view) {
    try { localStorage.setItem(STORAGE, view); } catch (e) { return; }
  }

  function parseFragment() {
    var pairs = {};
    var hash = location.hash.replace(/^#/, '');
    if (!hash) return pairs;
    hash.split('&').forEach(function (segment) {
      var eq = segment.indexOf('=');
      if (eq > 0) pairs[decodeURIComponent(segment.slice(0, eq))] = decodeURIComponent(segment.slice(eq + 1));
    });
    return pairs;
  }

  function initialState() {
    var frag = parseFragment();
    var view = frag[KEYS.view] || remembered();
    var page = parseInt(frag[KEYS.page], 10);

    return {
      view: view === 'list' ? 'list' : 'grid',
      sort: frag[KEYS.sort] === 'desc' ? 'desc' : 'asc',
      page: page > 0 ? page : 1
    };
  }

  function syncUrl(state) {
    var parts = [];
    Object.keys(KEYS).forEach(function (key) {
      var value = String(state[key]);
      if (value !== DEFAULTS[key]) parts.push(encodeURIComponent(KEYS[key]) + '=' + encodeURIComponent(value));
    });

    var fragment = parts.length ? '#' + parts.join('&') : '';
    var url = location.pathname + location.search + fragment;
    history.replaceState(history.state, '', url);
    remember(state.view);
  }

  function fill(template, values) {
    return template.replace(/%\{(\w+)\}/g, function (_, key) { return values[key]; });
  }

  function mount(root) {
    if (root.dataset.mounted) return;
    root.dataset.mounted = 'true';

    var data = root.dataset;
    var perPage = parseInt(data.perPage, 10) || 6;
    var list = root.querySelector('[data-dc-browse-items]');
    var items = list ? Array.prototype.slice.call(list.children) : [];
    if (!items.length) return;

    var controls = root.querySelector('[data-dc-browse-controls]');
    var viewButtons = root.querySelectorAll('[data-dc-browse-view]');
    var sortButton = root.querySelector('[data-dc-browse-sort]');
    var sortLabel = root.querySelector('[data-dc-browse-sort-label]');
    var pager = root.querySelector('[data-dc-browse-pager]');
    var live = root.querySelector('[data-dc-browse-live]');
    var state = initialState();
    var announced = false;

    function set(next) {
      state = next;
      render();
    }

    function button(label, attributes) {
      var el = document.createElement('button');
      el.type = 'button';
      el.className = 'dc-control';
      el.textContent = label;
      Object.keys(attributes).forEach(function (name) { el.setAttribute(name, attributes[name]); });
      return el;
    }

    function render() {
      var ascending = state.sort === 'asc';
      var sorted = items.slice().sort(function (a, b) {
        var order = a.dataset.title.localeCompare(b.dataset.title);
        return ascending ? order : -order;
      });
      var pageCount = Math.max(1, Math.ceil(sorted.length / perPage));
      var page = Math.min(Math.max(1, state.page), pageCount);
      var start = (page - 1) * perPage;
      var shown = sorted.slice(start, start + perPage);
      state.page = page;

      sorted.forEach(function (item, index) {
        item.hidden = index < start || index >= start + perPage;
        list.appendChild(item);
      });

      list.classList.toggle('dc-collections-list', state.view === 'list');

      Array.prototype.forEach.call(viewButtons, function (el) {
        el.setAttribute('aria-pressed', String(el.dataset.dcBrowseView === state.view));
      });

      var direction = ascending ? data.sortAsc : data.sortDesc;
      sortButton.dataset.direction = state.sort;
      sortLabel.textContent = direction;
      sortButton.setAttribute('aria-label', fill(data.sortAria, { direction: direction }));

      var focused = pager.contains(document.activeElement) ? document.activeElement.dataset : {};
      var focusedNav = focused.dcBrowseNav;
      var focusedPage = focused.dcBrowsePage;

      pager.innerHTML = '';
      pager.hidden = pageCount < 2;
      if (pageCount > 1) {
        var previous = button(data.previous, { 'data-dc-browse-nav': 'previous', 'data-dc-browse-page': String(page - 1) });
        previous.disabled = page <= 1;
        pager.appendChild(previous);
        for (var number = 1; number <= pageCount; number += 1) {
          var attributes = { 'data-dc-browse-page': String(number), 'aria-label': fill(data.page, { number: number }) };
          if (number === page) attributes['aria-current'] = 'page';
          pager.appendChild(button(String(number), attributes));
        }
        var next = button(data.next, { 'data-dc-browse-nav': 'next', 'data-dc-browse-page': String(page + 1) });
        next.disabled = page >= pageCount;
        pager.appendChild(next);
      }

      if (focusedNav || focusedPage) {
        var restore = (focusedNav && pager.querySelector('[data-dc-browse-nav="' + focusedNav + '"]:not([disabled])')) ||
          (focusedPage && pager.querySelector('[data-dc-browse-page="' + focusedPage + '"]:not([data-dc-browse-nav]):not([disabled])')) ||
          pager.querySelector('[aria-current="page"]');
        if (restore) restore.focus();
      }

      if (announced) {
        live.textContent = fill(data.status, {
          shown: shown.length, total: sorted.length, page: page, pages: pageCount,
          view: state.view === 'grid' ? data.viewGrid : data.viewList, sort: direction
        });
      }
      announced = true;

      syncUrl(state);
    }

    Array.prototype.forEach.call(viewButtons, function (el) {
      el.addEventListener('click', function () {
        set({ view: el.dataset.dcBrowseView, sort: state.sort, page: state.page });
      });
    });

    sortButton.addEventListener('click', function () {
      set({ view: state.view, sort: state.sort === 'asc' ? 'desc' : 'asc', page: 1 });
    });

    pager.addEventListener('click', function (event) {
      var target = event.target.closest('[data-dc-browse-page]');
      if (!target || target.disabled) return;
      set({ view: state.view, sort: state.sort, page: parseInt(target.dataset.dcBrowsePage, 10) });
    });

    controls.hidden = false;
    render();
  }

  function bind() {
    Array.prototype.forEach.call(document.querySelectorAll('[data-dc-browse]'), mount);
  }

  function release() {
    Array.prototype.forEach.call(document.querySelectorAll('[data-dc-browse]'), function (root) {
      delete root.dataset.mounted;
    });
  }

  document.addEventListener('DOMContentLoaded', bind);
  document.addEventListener('turbolinks:load', bind);
  document.addEventListener('turbolinks:before-cache', release);
}();
