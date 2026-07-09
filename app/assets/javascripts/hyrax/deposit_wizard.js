// Progressive enhancement for the guided deposit wizard. Attaches behavior to
// wizard steps by class when present; a no-op on other pages.
(function () {
  function initFileUploader() {
    var uploader = $('.fileupload-deposit-wizard');
    if (!uploader.length || typeof $.fn.hyraxUploader !== 'function') return;
    uploader.hyraxUploader({
      maxNumberOfFiles: uploader.data('max-number-of-files'),
      maxFileSize: uploader.data('max-file-size'),
      uploadTemplateId: 'deposit-wizard-template-upload',
      downloadTemplateId: 'deposit-wizard-template-download'
    });
  }

  // Visibility pills: mark the selected pill, expand its embargo/lease panel (by
  // the radio's data-target), and show the selected option's description. Scoped
  // per block so each control (work details, and one per file) drives only itself.
  function initVisibility() {
    $('[data-behavior="visibility"]').each(function () {
      var scope = $(this);
      var options = scope.find('[data-behavior="visibility-option"]');
      var desc = scope.find('[data-behavior="visibility-desc"]');
      scope.find('.collapse').collapse({ toggle: false });

      function sync() {
        var checked = options.filter(':checked');
        var target = checked.data('target');
        scope.find('.deposit-wizard__visibility-pill').removeClass('is-selected');
        checked.closest('.deposit-wizard__visibility-pill').addClass('is-selected');
        scope.find('.collapse').collapse('hide');
        if (target) scope.find(target).collapse('show');
        // Move the selected option's title (its description) into the desc line.
        desc.html(checked.closest('.deposit-wizard__visibility-pill').attr('title') || '');

        // Embargo/lease sub-fields are required only when their option is chosen.
        // A required field inside a hidden collapse would block submit invisibly,
        // so toggle `required` to match the current selection.
        var value = checked.val();
        scope.find('[data-behavior="embargo-field"]').prop('required', value === 'embargo');
        scope.find('[data-behavior="lease-field"]').prop('required', value === 'lease');
      }

      options.on('change', sync);
      sync();
    });
  }

  // Per-file "same as the work" toggle: when checked, the file follows the work's
  // visibility and its own visibility form is hidden; unchecking reveals it.
  function initFileVisibilityInherit() {
    $('[data-behavior="file-visibility"]').each(function () {
      var block = $(this);
      var checkbox = block.find('[data-behavior="inherit-visibility"]');
      var ownVisibility = block.find('.deposit-wizard__own-visibility');
      if (!checkbox.length || !ownVisibility.length) return;
      function sync() { ownVisibility.prop('hidden', checkbox.prop('checked')); }
      checkbox.on('change', sync);
      sync();
    });
  }

  // Disable the Deposit button until the active deposit-agreement checkbox is
  // ticked. Passive mode has no checkbox, so the button stays enabled.
  function initDepositAgreement() {
    var checkbox = $('#agreement');
    var button = $('.deposit-wizard__deposit-btn');
    if (!checkbox.length || !button.length) return;
    function sync() { button.prop('disabled', !checkbox.prop('checked')); }
    checkbox.on('change', sync);
    sync();
  }

  // Work-type selection: clicking a card selects it (marks .is-selected, clears
  // siblings) and enables the step's Next button.
  function initTypeSelect() {
    var group = $('[data-behavior="type-select"]');
    if (!group.length) return;
    var next = $('[data-behavior="type-next"]');
    group.find('[data-behavior="type-option"]').on('change', function () {
      group.find('.deposit-wizard__type-card').removeClass('is-selected');
      $(this).closest('.deposit-wizard__type-card').addClass('is-selected');
      next.prop('disabled', false);
    });
  }

  function showFilePanel(layout, target) {
    layout.find('[data-behavior="file-tab"]').each(function () {
      $(this).toggleClass('is-active', $(this).data('file-target').toString() === target);
    });
    layout.find('[data-behavior="file-panel"]').each(function () {
      var match = $(this).data('file-id').toString() === target;
      $(this).toggleClass('is-active', match).prop('hidden', !match);
    });
  }

  // File-detail master-detail: clicking a sidebar file shows that file's form
  // panel and hides the others. All panels stay in the DOM so every file's fields
  // submit together; only visibility changes.
  function initFileMeta() {
    var layout = $('[data-behavior="file-meta"]');
    if (!layout.length) return;
    layout.find('[data-behavior="file-tab"]').on('click', function () {
      showFilePanel(layout, $(this).data('file-target').toString());
    });
  }

  // Disable a step's Next button until the form's required fields are valid.
  // Re-checks on input/change. On the file-detail step, a required field can live
  // in a hidden file panel; when the user tries to advance with such a field
  // invalid, switch to that file and flag its sidebar tab so the reason is visible
  // (otherwise Next would silently do nothing).
  function initStepValidity() {
    var form = document.querySelector('.deposit-wizard__details-form, .deposit-wizard__file-meta-form');
    if (!form) return;
    var next = form.querySelector('.deposit-wizard__next-btn');
    if (!next) return;

    var layout = $('[data-behavior="file-meta"]');

    // On the file-detail step, required fields live in per-file panels (some
    // hidden). Flag each sidebar tab whose panel has an invalid field, so the user
    // can see WHICH file blocks Next even while Next is disabled (a disabled button
    // fires no click, so we can't rely on a click to reveal the error).
    function flagInvalidFiles() {
      if (!layout.length) return;
      layout.find('[data-behavior="file-panel"]').each(function () {
        var id = this.getAttribute('data-file-id');
        var invalid = this.querySelector(':invalid') !== null;
        layout.find('[data-file-target="' + id + '"]').toggleClass('has-error', invalid);
      });
    }

    function refresh() {
      next.disabled = !form.checkValidity();
      flagInvalidFiles();
    }

    form.addEventListener('input', refresh);
    form.addEventListener('change', refresh);
    refresh();
  }

  function initDepositWizard() {
    // Idempotency guard: this handler is bound to both `turbolinks:load` and
    // `ready`, which can both fire on a full page load. Running the inits twice
    // re-initializes Bootstrap collapse widgets and re-binds handlers, which can
    // duplicate the visibility panel. Mark the wizard as initialized so a second
    // firing is a no-op; the flag is cleared before each Turbolinks navigation so
    // the next page initializes fresh.
    var root = document.querySelector('.deposit-wizard');
    if (!root || root.dataset.dwInitialized === 'true') return;
    root.dataset.dwInitialized = 'true';

    initFileUploader();
    initVisibility();
    initFileVisibilityInherit();
    initTypeSelect();
    initFileMeta();
    initStepValidity();
    initDepositAgreement();
  }

  $(document).on('turbolinks:load ready', initDepositWizard);
  $(document).on('turbolinks:before-render', function () {
    var root = document.querySelector('.deposit-wizard');
    if (root) { delete root.dataset.dwInitialized; }
  });
})();
