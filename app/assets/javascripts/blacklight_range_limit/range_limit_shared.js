// Load the gem's own blacklight_range_limit 8.5.0 UMD bundle.
//
// 8.5.0 ships the umd and esm builds under this directory, but Hyku's three
// `//= require`s resolved to vendored pre-8 copies that defined the global the
// old way and never called `initialize`. This file replaces the vendored
// range_limit_shared.js to load the gem's version-matched bundle instead.
//
//= require blacklight_range_limit/blacklight_range_limit.umd

if (window.hyku_stashed_amd_define) {
  window.define = window.hyku_stashed_amd_define;
  window.hyku_stashed_amd_define = null;
}

(function () {
  var jq = window.jQuery;
  var rangeLimit = window.BlacklightRangeLimit;
  var blacklight = window.Blacklight;

  if (!jq || !rangeLimit || !blacklight) return;

  // Disable chart hover tooltips. The gem builds tooltip titles from segment
  // labels (rendered HTML markup), so they display raw `<span class="from"...>`
  // text. Worse, the gem calls Bootstrap's `tooltip('hide')`, but jQuery UI
  // (loaded after Bootstrap) owns `$.fn.tooltip` and throws on `_fixTitle` and
  // `hide`. Clearing `grid.hoverable` on the flot plot stops `plothover` from
  // firing at the source.
  rangeLimit.disableChartHover = function (container) {
    var plot = container.data('plot');

    if (plot && plot.getOptions && plot.getOptions().grid) {
      plot.getOptions().grid.hoverable = false;
    }

    container.off('mouseout').off('plothover');

    var describedBy = container.attr('aria-describedby');
    var stale = describedBy && document.getElementById(describedBy);

    if (stale) stale.parentNode.removeChild(stale);

    container.removeAttr('title').removeAttr('aria-describedby');
  };

  // Attached at file scope so it cannot miss the chart `initialize` draws
  // synchronously for an already-open facet.
  jq(document).on(rangeLimit.redrawnEvent, function (event) {
    rangeLimit.disableChartHover(jq(event.target));
  });

  blacklight.onLoad(function () {
    var modalSelector = (blacklight.modal && blacklight.modal.modalSelector) ||
      (blacklight.Modal && blacklight.Modal.modalSelector);

    rangeLimit.initialize(modalSelector);
  });
})();
