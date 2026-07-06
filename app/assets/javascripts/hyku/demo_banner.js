// Hides the public demo tenant banner for the rest of the day once a visitor
// dismisses it. Dismissal is client-side only (a cookie) so pages stay
// cacheable; the banner returns after the cookie expires, which roughly
// matches the nightly reset cadence.
(function () {
  var COOKIE = 'hyku_demo_banner_dismissed';

  function dismissed() {
    return document.cookie.split('; ').indexOf(COOKIE + '=1') !== -1;
  }

  function rememberDismissal() {
    var expires = new Date(Date.now() + 24 * 60 * 60 * 1000);
    document.cookie = COOKIE + '=1; path=/; expires=' + expires.toUTCString() + '; SameSite=Lax';
  }

  document.addEventListener('turbolinks:load', function () {
    var banner = document.getElementById('demo-banner');
    if (!banner) return;
    if (dismissed()) {
      banner.remove();
      return;
    }
    $(banner).on('closed.bs.alert', rememberDismissal);
  });
})();
