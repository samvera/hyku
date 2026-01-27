// Appearance page tab and scroll management
(function() {
  // Disable browser's native scroll restoration - we'll handle it ourselves
  if ('scrollRestoration' in history) {
    history.scrollRestoration = 'manual';
  }

  // Firefox-specific: Prevent scroll on hash change by intercepting early
  var savedHash = null;
  if (window.location.hash) {
    savedHash = window.location.hash;
    // Remove hash IMMEDIATELY before Firefox can use it for scrolling
    history.replaceState(null, null, window.location.pathname + window.location.search);
  }

  function activateTabFromHash() {
    // Use saved hash if we removed it early, otherwise check URL
    var hash = savedHash || window.location.hash;
    savedHash = null; // Clear it after using

    if (hash && hash.length > 1) {
      var tabId = hash.substring(1);
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

        // Ensure hash stays removed
        if (window.history && window.history.replaceState && window.location.hash) {
          window.history.replaceState(null, null, window.location.pathname + window.location.search);
        }
      }
    }
  }

  // Run on initial page load
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', activateTabFromHash);
  } else {
    activateTabFromHash();
  }

  // Force scroll to top repeatedly for a longer duration (Firefox needs more time)
  // This handles Firefox's aggressive scroll restoration
  function forceScrollToTop() {
    var startTime = Date.now();
    var duration = 500; // Increased to 500ms for Firefox

    function scrollLoop() {
      window.scrollTo(0, 0);
      if (Date.now() - startTime < duration) {
        requestAnimationFrame(scrollLoop);
      }
    }
    scrollLoop();
  }

  // Start forcing scroll to top immediately
  forceScrollToTop();

  // Turbolinks event handlers
  if (typeof Turbolinks !== 'undefined') {
    // Before caching: clear scroll position so it's not restored later
    document.addEventListener('turbolinks:before-cache', function() {
      window.scrollTo(0, 0);
    });

    // Before visit: save and remove hash to prevent Firefox scroll
    document.addEventListener('turbolinks:before-visit', function() {
      if (window.location.hash) {
        savedHash = window.location.hash;
        history.replaceState(null, null, window.location.pathname + window.location.search);
      }
    });

    // After render: activate tab and force scroll to top
    document.addEventListener('turbolinks:render', function() {
      activateTabFromHash();
      forceScrollToTop();
    });

    // On load: ensure we're at top and activate tab
    document.addEventListener('turbolinks:load', function() {
      activateTabFromHash();
      forceScrollToTop();
    });
  }
})();

// Appearance forms - ensure correct tab is maintained after save
$(document).on('turbolinks:load', function() {
  // Handle all appearance forms to maintain active tab after submit
  $('#logo-image-form, #favicon-form, #banner-image-form, #directory-image-form, ' +
    '#default-images-form, #colors-form, #fonts-form, #css-form, #themes-form').on('submit', function() {
    // Clear Turbolinks cache to prevent scroll position restoration
    if (typeof Turbolinks !== 'undefined') {
      Turbolinks.clearCache();
    }
    
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
