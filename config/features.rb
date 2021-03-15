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
end
