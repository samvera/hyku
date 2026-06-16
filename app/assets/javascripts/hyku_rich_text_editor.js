// Attaches a TinyMCE WYSIWYG editor to any textarea that Hyrax's flexible
// rich-text edit field renders for a `form: { input_type: rich_text }` property.
// Hyrax emits an engine-agnostic `<textarea class="rich-text">`; this is the
// Hyku-side hook that turns it into a what-you-see-is-what-you-get editor whose
// HTML output is stored on the field and rendered (sanitized) on the show page.
(function () {
  function initRichTextEditors() {
    if (typeof tinymce === 'undefined') { return; }
    // Avoid double-initialization on Turbo/AJAX re-renders.
    tinymce.remove('textarea.rich-text');
    tinymce.init({
      selector: 'textarea.rich-text',
      menubar: false,
      branding: false,
      plugins: 'lists link autolink code',
      toolbar: 'undo redo | bold italic underline | bullist numlist | blockquote link | removeformat | code',
      // Keep the stored markup aligned with HtmlAttributeRenderer's allow-list.
      valid_elements: 'p,br,strong/b,em/i,u,s,a[href|title|target|rel],ul,ol,li,blockquote,h1,h2,h3,h4,h5,h6,code,pre,span'
    });
  }

  document.addEventListener('DOMContentLoaded', initRichTextEditors);
  document.addEventListener('turbo:load', initRichTextEditors);
  document.addEventListener('turbolinks:load', initRichTextEditors);
})();
