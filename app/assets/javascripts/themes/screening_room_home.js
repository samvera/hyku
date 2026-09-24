// Opening a player focuses its media element, which is what makes the space
// bar play and the arrow keys seek; closing one stops the media, which the
// modal does not do. The rotation itself is held by themes/spotlight.js.
+function ($) {
  'use strict';

  function bind() {
    $(document)
      .off('.scrPlayer')
      .on('shown.bs.modal.scrPlayer', '.scr-player', function () {
        var media = $(this).find('video, audio')[0];
        if (media) media.focus();
      })
      .on('hidden.bs.modal.scrPlayer', '.scr-player', function () {
        $(this).find('video, audio').each(function () {
          this.pause();
          this.currentTime = 0;
        });
      });
  }

  $(bind);
  $(document).on('turbolinks:load', bind);
}(jQuery);
