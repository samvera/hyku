// Default Images form
$(document).on('turbolinks:load', function() {
  $('#default_images .panel-footer input[name="commit"]').click(function(e) {
    // Prevent ActionController::ParameterMissing error by not
    // allowing a blank form to be submit. Blank inputs are allowed,
    // as long as at least one input has a value.
    if (inputsWithValueCount() < 1) {
      e.preventDefault();
      alert($('[data-alert]').data('alert'));
    }
  });

  function inputsWithValueCount() {
    var inputsWithValue = [];
    var inputs = $('#default_images input[type="file"]');

    inputs.each(function() {
      if ($(this).val().length > 0) { inputsWithValue.push($(this)); }
    });

    return inputsWithValue.length;
  }
});
