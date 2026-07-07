// Progressive enhancement for the guided deposit wizard. Attaches behavior to
// wizard steps by class when present; a no-op on other pages. Mirrors Bulkrax's
// importers.js approach (behavior in a required asset, not inline in views).
(function () {
  function initFileUploader() {
    var uploader = $('.fileupload-deposit-wizard');
    if (!uploader.length || typeof $.fn.hyraxUploader !== 'function') return;
    uploader.hyraxUploader({
      maxNumberOfFiles: uploader.data('max-number-of-files'),
      maxFileSize: uploader.data('max-file-size')
    });
  }

  // Reveal a visibility option's sub-fields (embargo/lease dates) when its radio
  // is chosen. The stock deposit form does this via VisibilityComponent, which is
  // wired only into its own save-work JS; replicate just the collapse toggling.
  function initVisibility() {
    var scope = $('.deposit-wizard__visibility .visibility');
    if (!scope.length) return;
    scope.find('.collapse').collapse({ toggle: false });
    function openSelected() {
      var target = scope.find("input[type='radio']:checked").data('target');
      scope.find('.collapse').collapse('hide');
      if (target) scope.find('.collapse' + target).collapse('show');
    }
    scope.find("input[type='radio']").on('change', openSelected);
    openSelected();
  }

  // Disable the Deposit button until the active deposit-agreement checkbox is
  // ticked, matching the stock deposit form (which disables its save button via
  // DepositAgreement). Passive mode has no checkbox, so the button stays enabled.
  function initDepositAgreement() {
    var checkbox = $('#agreement');
    var button = $('.deposit-wizard__deposit-btn');
    if (!checkbox.length || !button.length) return;
    function sync() { button.prop('disabled', !checkbox.prop('checked')); }
    checkbox.on('change', sync);
    sync();
  }

  function initDepositWizard() {
    initFileUploader();
    initVisibility();
    initDepositAgreement();
  }

  $(document).on('turbolinks:load ready', initDepositWizard);
})();
