/**
 * This file is used to conditionally require fields on the edit/new work forms.
 * At the moment, rights statement is required by default, and rights notes is not.
 * One or the other must be filled out in order to create/update a work
 */

// check the value of the rights statement and rights notes fields on page load
$(document).on('turbolinks:load', function () {
  $('#generic_work_rights_statement').each(function () {
    if (this.value || $('#generic_work_rights_notes')[0].value) return;

    $('#generic_work_rights_statement').attr('required', true);
    $('#generic_work_rights_notes').attr('required', true);
  });
});

// check the value of the rights notes field after its focus is removed
$(document).on('turbolinks:load', function () {
  return $('body').on('blur', '#generic_work_rights_notes', function () {
    if (this.value === undefined) return;
    $('#generic_work_rights_notes').attr('required', true);

    if (this.value === '') {
      $('#generic_work_rights_statement').attr('required', true);
    } else {
      $('#generic_work_rights_statement').attr('required', false);
    }
  });
});

// check the value of the rights statement field after its focus is removed
$(document).on('turbolinks:load', function () {
  return $('body').on('blur', '#generic_work_rights_statement', function () {
    if (this.value === undefined || !this.value) return;
    $('#generic_work_rights_statement').attr('required', true);

    if (this.value === '') {
      $('#generic_work_rights_notes').attr('required', true);
    } else {
      $('#generic_work_rights_notes').attr('required', false);
    }
  });
});
