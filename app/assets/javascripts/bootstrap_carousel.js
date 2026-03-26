+function ($) {
  'use strict';

  function initializeCarousels() {
    $('.carousel[data-ride="carousel"]').each(function () {
      var $carousel = $(this)
      $carousel.carousel($carousel.data())
    })
  }

  $(window).on('load', function () {
    initializeCarousels()
  })

  $(document).on('turbolinks:load', function () {
    initializeCarousels()
  })

}(jQuery);
