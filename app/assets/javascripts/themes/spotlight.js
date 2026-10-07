// Shared rotation controls for the themes' spotlight carousels. They run with
// data-pause="false" because Bootstrap's hover handling reads the removal of a
// modal overlay as a fresh mouseenter and pauses a carousel the reader never
// hovered. The hold button is the reader's way to stop and resume auto-advance.
// Clicking an indicator also holds, since a manual navigation implies the reader
// wants to stay on the chosen slide. Only the hold button resumes.
// A slide change is refused while a modal is open so the work being viewed is
// still the work on screen when the modal closes.
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
        $(this).find('.carousel-item').each(function (i) {
          $(this).find('a, button').attr('tabindex', i === event.to ? null : '-1');
        });
      })
      .on('click.themeSpotlight', '[data-slide-to]', function () {
        var region = $(this).closest('[data-theme-spotlight]');
        var button = region.find('[data-spotlight-hold]');
        if (button.attr('data-held') === 'true') return;
        hold(region, button, true);
      })
      .on('click.themeSpotlight', '[data-spotlight-hold]', function () {
        var button = $(this);

        hold(button.closest('[data-theme-spotlight]'), button, button.attr('data-held') !== 'true');
      });
  }

  $(bind);
  $(document).on('turbolinks:load', bind);
}(jQuery);
