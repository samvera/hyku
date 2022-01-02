// Fonts form
Blacklight.onLoad(function() {
  if($("#admin_appearance_body_font").length > 0) {
    $("#admin_appearance_body_font").fontselect({lookahead: 20});
    $("#admin_appearance_headline_font").fontselect({lookahead: 20});
  }

  $('div.defaultable-fonts a.restore-default-font').click(function(e) {
    e.preventDefault();
    var defaultTarget = $(e.target).data('default-target');
    var input         = $("input[name='admin_appearance["+ defaultTarget +"]']");
    var defaultValue  = input.data('default-value').replace(';', '');
    var inputDisplay  = $("div[class$='"+ defaultTarget +"']").find('div.font-select span');

    input.val(defaultValue);
    inputDisplay.css("font-family", defaultValue);
    inputDisplay.text(defaultValue);
  });

  $('.panel-footer a.restore-all-default-fonts').click(function(e) {
    e.preventDefault();

    var allFontInputs = $("input[name*='font']");

    allFontInputs.each(function() {
      var thisTarget   = $(this).attr('id').replace('admin_appearance_', '');
      var defaultValue = $(this).data('default-value').replace(';', '');
      var inputDisplay = $("div[class$='"+ thisTarget +"']").find('div.font-select span');

      $(this).val(defaultValue);
      inputDisplay.css("font-family", defaultValue);
      inputDisplay.text(defaultValue);
    });
  });
});
