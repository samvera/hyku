// Shared rotation controls for the themes' spotlight carousels. They run with
// data-pause="false" because Bootstrap's hover handling reads the removal of a
// modal overlay as a fresh mouseenter and pauses a carousel the reader never
// hovered. That leaves no hover pause, so the hold button is the reader's way
// to stop the auto-advance, and it stays stopped until they press it again.
// Focus inside the region holds it too, since the outgoing slide is hidden and
// a reader tabbing through it would otherwise lose their place. A slide change
// is refused while a modal is open so the work being viewed is still the work
// on screen when the modal closes.
+function ($) {
  'use strict';

  function hold(region, button, held) {
    region.carousel(held ? 'pause' : 'cycle');
    button.attr('data-held', held ? 'true' : 'false')
          .find('[data-spotlight-hold-label]').text(button.data(held ? 'resumeLabel' : 'holdLabel'));
  }

  function bind() {
    $(document)
      .off('.themeSpotlight')
      .on('slide.bs.carousel.themeSpotlight', '[data-theme-spotlight]', function (event) {
        if ($('.modal.show').length) event.preventDefault();
      })
      .on('slid.bs.carousel.themeSpotlight', '[data-theme-spotlight]', function (event) {
        $(this).find('[data-slide-to]').each(function () {
          var current = Number($(this).attr('data-slide-to')) === event.to;

          $(this).toggleClass('is-current', current).attr('aria-current', current);
        });
      })
      .on('focusin.themeSpotlight', '[data-theme-spotlight]', function (event) {
        var button = $(this).find('[data-spotlight-hold]');
        if ($(event.target).closest('[data-spotlight-hold]').length) return;
        if (button.attr('data-held') === 'true') return;

        hold($(this), button, true);
      })
      .on('click.themeSpotlight', '[data-spotlight-hold]', function () {
        var button = $(this);

        hold(button.closest('[data-theme-spotlight]'), button, button.attr('data-held') !== 'true');
      });
  }

  $(bind);
  $(document).on('turbolinks:load', bind);
}(jQuery);
