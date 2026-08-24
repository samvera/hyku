$(document).on('turbolinks:load', function () {
  var fields = document.querySelectorAll('.vocabulary-field');
  if (!fields.length) return;

  function toggle(field, editing) {
    $(field).find('.vocabulary-field-display').toggleClass('d-none', editing);
    $(field).find('.vocabulary-field-form').toggleClass('d-none', !editing);
    if (editing) $(field).find('input[type=text], textarea').trigger('focus');
  }

  $('.vocabulary-field').on('click', '.vocabulary-field-edit', function (event) {
    event.preventDefault();
    $('.vocabulary-field').each(function () { toggle(this, false); });
    toggle($(this).closest('.vocabulary-field'), true);
  });

  $('.vocabulary-field').on('click', '.vocabulary-field-cancel', function () {
    var field = $(this).closest('.vocabulary-field');
    field.find('form')[0].reset();
    toggle(field, false);
    field.find('.vocabulary-field-edit').trigger('focus');
  });
});
