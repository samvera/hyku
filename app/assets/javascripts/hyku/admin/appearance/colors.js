// Immediately activate the correct tab based on URL hash to prevent flash
(function() {
  function activateTabFromHash() {
    var hash = window.location.hash;
    if (hash && hash.length > 1) {
      var tabId = hash.substring(1); // Remove the #
      var tabLink = document.querySelector('a[href="#' + tabId + '"]');
      var tabPane = document.getElementById(tabId);
      
      if (tabLink && tabPane) {
        // Remove active from all tabs and panes
        var allTabLinks = document.querySelectorAll('.nav-tabs .nav-link');
        var allTabPanes = document.querySelectorAll('.tab-pane');
        
        for (var i = 0; i < allTabLinks.length; i++) {
          allTabLinks[i].classList.remove('active');
        }
        for (var j = 0; j < allTabPanes.length; j++) {
          allTabPanes[j].classList.remove('active', 'show');
        }
        
        // Activate the correct tab and pane
        tabLink.classList.add('active');
        tabPane.classList.add('active', 'show');
      }
    }
  }
  
  // Run immediately if DOM is ready, otherwise wait for it
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', activateTabFromHash);
  } else {
    activateTabFromHash();
  }
  
  // Also handle turbolinks navigation
  if (typeof Turbolinks !== 'undefined') {
    document.addEventListener('turbolinks:load', activateTabFromHash);
  }
})();

// Appearance forms - ensure correct tab is maintained after save
$(document).on('turbolinks:load', function() {
  // Handle all appearance forms to maintain active tab after submit
  $('#logo-image-form, #favicon-form, #banner-image-form, #directory-image-form, ' +
    '#default-images-form, #colors-form, #fonts-form, #css-form, #themes-form').on('submit', function() {
    // Find the active tab
    var activeTab = $('.nav-tabs .nav-link.active').attr('href');
    if (activeTab) {
      // Remove the # from the href to get the tab ID
      var tabId = activeTab.replace('#', '');
      // Find the return_tab hidden field in this form and update it
      var returnTabField = $(this).find('input[name="return_tab"]');
      if (returnTabField.length) {
        returnTabField.val(tabId);
      }
    }
  });

  $('div.defaultable-colors a.restore-default-color').click(function(e) {
    e.preventDefault();

    var defaultTarget = $(e.target).data('default-target');
    var input = $("input[name='admin_appearance["+ defaultTarget +"]']");

    input.val(input.data('default-value'));
  });

  $('.card-footer a.reset-to-system-defaults').click(function(e) {
    e.preventDefault();

    var allColorInputs = $("input[name*='color']");

    allColorInputs.each(function() {
      var systemDefault = $(this).attr('data-system-default');
      $(this).val(systemDefault);
    });
  });

  $('.card-footer a.restore-tenant-defaults').click(function(e) {
    e.preventDefault();

    var allColorInputs = $("input[name*='color']");

    allColorInputs.each(function() {
      var tenantDefault = $(this).attr('data-tenant-default');
      var systemDefault = $(this).attr('data-system-default');
      $(this).val(tenantDefault || systemDefault);
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
