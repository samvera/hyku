// Holds the spotlight while a modal is open, so the work being played is still
// the work on screen when the modal closes. The hold is a guard on the slide
// rather than a pause: the carousel runs with data-pause="false" because
// Bootstrap's hover handling reads the removal of the modal overlay as a fresh
// mouseenter and pauses a carousel the reader never hovered. That leaves no
// hover pause, so the hold button is the reader's way to stop the auto-advance,
// and it stays stopped until they press it again. Focus stops it too: the
// outgoing slide is hidden, so a reader tabbing through a slide would otherwise
// lose their place mid-rotation. Opening a player focuses its
// media element, which is what makes the space bar play and the arrow keys seek;
// closing one stops the media, which the modal does not do.
+function ($) {
  'use strict';

  function bind() {
    $(document)
      .off('.scrSpotlight')
      .on('slide.bs.carousel.scrSpotlight', '#scr-spotlight', function (event) {
        if ($('.modal.show').length) event.preventDefault();
      })
      .on('slid.bs.carousel.scrSpotlight', '#scr-spotlight', function (event) {
        $(this).find('.scr-spotlight-segment').each(function (position) {
          var current = position === event.to;

          $(this).toggleClass('is-current', current).attr('aria-current', current);
        });
      })
      .on('focusin.scrSpotlight', '#scr-spotlight', function (event) {
        var button = $(this).find('[data-scr-spotlight-hold]');
        if ($(event.target).closest('[data-scr-spotlight-hold]').length) return;
        if (button.attr('data-held') === 'true') return;

        $(this).carousel('pause');
        button.attr('data-held', 'true')
              .find('[data-scr-spotlight-hold-label]').text(button.data('resumeLabel'));
      })
      .on('click.scrSpotlight', '[data-scr-spotlight-hold]', function () {
        var button = $(this);
        var held = button.attr('data-held') === 'true';
        var labels = { hold: button.data('holdLabel'), resume: button.data('resumeLabel') };

        $('#scr-spotlight').carousel(held ? 'cycle' : 'pause');
        button.attr('data-held', held ? 'false' : 'true')
              .find('[data-scr-spotlight-hold-label]').text(held ? labels.hold : labels.resume);
      })
      .on('shown.bs.modal.scrSpotlight', '.scr-player', function () {
        var media = $(this).find('video, audio')[0];
        if (media) media.focus();
      })
      .on('hidden.bs.modal.scrSpotlight', '.scr-player', function () {
        $(this).find('video, audio').each(function () {
          this.pause();
          this.currentTime = 0;
        });
      });
  }

  $(bind);
  $(document).on('turbolinks:load', bind);
}(jQuery);
