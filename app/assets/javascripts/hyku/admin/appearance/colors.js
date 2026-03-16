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

  $('.card-footer a.apply-tenant-colors').click(function(e) {
    e.preventDefault();

    var tenantColors = $(this).data('tenant-colors');

    Object.keys(tenantColors).forEach(function(colorName) {
      var input = $("input[name='admin_appearance[" + colorName + "]']");
      if (input.length) {
        input.val(tenantColors[colorName]);
      }
    });
  });

  $('.card-footer a.save-tenant-colors').click(function(e) {
    e.preventDefault();

    var saveUrl = $(this).data('save-url');
    var allColorInputs = $("input[name*='color']");
    var colorData = {};

    allColorInputs.each(function() {
      var name = $(this).attr('name');
      var match = name.match(/admin_appearance\[(.+)\]/);
      if (match) {
        colorData[match[1]] = $(this).val();
      }
    });

    $.ajax({
      url: saveUrl,
      method: 'POST',
      data: { admin_appearance: colorData },
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      },
      success: function() {
        window.location.reload();
      },
      error: function(xhr) {
        alert('Error saving tenant colors: ' + xhr.statusText);
      }
    });
  });
});
