# frozen_string_literal: true

Flipflop.configure do
  feature :home_page_recent_document_show_depositor,
          default: false, # Default to false as this is PALNI/PALCI preference
          description: "Shows the depositor of each homepage's recent documents."

  feature :home_page_recent_document_show_keyword,
          default: false, # Default to false as this is PALNI/PALCI preference
          description: "Shows the keywords of each homepage's recent documents."

  feature :show_workflow_roles_menu_item_in_admin_dashboard_sidebar,
          default: false,
          description: "Shows the Workflow Roles menu item in the admin dashboard sidebar."

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

  feature :show_identity_provider_in_admin_dashboard,
          default: false,
          description: "Shows the Identity Provider tab on the admin dashboard."

  # Flipflop.default_pdf_viewer? returning `true` means we use PDF.js and `false` means we use IIIF Print.
  feature :default_pdf_viewer,
          default: true,
          description: "Choose PDF.js or Universal Viewer to render PDFs. UV uses IIIF Print and requires PDF splitting with OCR. Switching from PDF.js to the UV may require re-ingesting of the PDF."

  feature :show_login_link,
          default: true,
          description: "Show General Login Link at Top Right of Page."

  feature :treat_some_user_inputs_as_markdown,
          default: false,
          description: "Treat some user inputs (e.g. titles and descriptions) as markdown."
end
