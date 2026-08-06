// Preserve scroll position on the admin Features page across a feature-toggle
// submit. Each toggle is its own form that POSTs and reloads the page, which
// otherwise jumps the admin back to the top. Scoped to the features page: the
// early return makes this a no-op everywhere else (it is in the global bundle).
$(document).on('turbolinks:load', function () {
  var page = document.querySelector('.flip.row form[action*="feature"]');
  if (!page) return;

  var KEY = 'adminFeaturesScroll';

  document.addEventListener('submit', function () {
    sessionStorage.setItem(KEY, window.scrollY);
  });

  var y = sessionStorage.getItem(KEY);
  if (y !== null) {
    window.scrollTo(0, parseInt(y, 10));
    sessionStorage.removeItem(KEY);
  }
});
