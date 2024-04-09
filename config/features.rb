# frozen_string_literal: true

Flipflop.configure do
  feature :show_featured_researcher,
          default: true,
          description: "Shows the Featured Researcher tab on the homepage."

  feature :show_share_button,
          default: true,
          description: "Shows the 'Share Your Work' button on the homepage."

  feature :show_featured_works,
          default: true,
          description: "Shows the Featured Works tab on the homepage."

  feature :show_recently_uploaded,
          default: true,
          description: "Shows the Recently Uploaded tab on the homepage."
  # Flipflop.default_pdf_viewer? returning `true` means we use PDF.js and `false` means we use IIIF Print.
  feature :default_pdf_viewer,
          default: true,
          description: "Choose PDF.js or Universal Viewer to render PDFs. UV uses IIIF Print and requires PDF splitting with OCR. Switching from PDF.js to the UV may require re-ingesting of the PDF."
end
