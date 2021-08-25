// Colors form
$(document).on('turbolinks:load', function() {
  $('div.defaultable-colors a.restore-default-color').click(function(e) {
    e.preventDefault();

    var defaultTarget = $(e.target).data('default-target');
    var input = $("input[name='admin_appearance["+ defaultTarget +"]']");

    input.val(input.data('default-value'));
  });

  $('.panel-footer a.restore-all-default-colors').click(function(e) {
    e.preventDefault();

    var allColorInputs = $("input[name*='color']");

    allColorInputs.each(function() {
      $(this).val($(this).data('default-value'));
    });
  });
});
