// Colors form
$(document).on('turbolinks:load', function() {
  $('div.defaultable-colors a.restore-default-color').click(function(e) {
    e.preventDefault();

    var defaultTarget = $(e.target).data('default-target');
    var input = $("input[name='admin_appearance["+ defaultTarget +"]']");

    input.val(input.data('default-value'));
  });

  $('.card-footer a.restore-all-default-colors').click(function(e) {
    e.preventDefault();

    var allColorInputs = $("input[name*='color']");

    allColorInputs.each(function() {
      $(this).val($(this).data('default-value'));
    });
  });

  $('.card-footer a.apply-theme-colors').click(function(e) {
    e.preventDefault();

    var themeColors = $(this).data('theme-colors');
    
    Object.keys(themeColors).forEach(function(colorName) {
      var input = $("input[name='admin_appearance[" + colorName + "]']");
      if (input.length) {
        input.val(themeColors[colorName]);
      }
    });
  });
});
