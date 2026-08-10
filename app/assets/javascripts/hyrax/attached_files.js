// Reveals the "new files" heading on the work form's Files tab once the
// uploader holds a file.
//
// This cannot be done in CSS: jQuery File Upload injects the rows at runtime,
// and the heading precedes their container in the DOM, so there is no sibling
// selector that reaches them.
(function () {
  function initAttachedFilesHeading() {
    var heading = document.querySelector('[data-behavior="new-files-heading"]');
    if (!heading) return;

    var rows = document.querySelector('#fileupload tbody.files');
    if (!rows) return;

    function sync() {
      heading.hidden = rows.children.length === 0;
    }

    // The plugin swaps rows in and out (upload template → download template,
    // and removal on Delete), so watch the container rather than binding to
    // any one of its events.
    new MutationObserver(sync).observe(rows, { childList: true });
    sync();
  }

  $(document).on('turbolinks:load ready', initAttachedFilesHeading);
})();
