# frozen_string_literal: true

module InstitutionalRepositoryHelper
  IR_RESOURCE_TYPE_ICONS = {
    "Article" => "fa-file-text-o",
    "Audio" => "fa-headphones",
    "Book" => "fa-book",
    "Capstone Project" => "fa-folder-open",
    "Collection" => "fa-archive",
    "Conference Proceeding" => "fa-file-powerpoint-o",
    "Dataset" => "fa-database",
    "Dissertation" => "fa-file-text-o",
    "Event" => "fa-calendar",
    "Image" => "fa-picture-o",
    "InteractiveResource" => "fa-hand-pointer-o",
    "Journal" => "fa-newspaper-o",
    "Map or Cartographic Material" => "fa-map-o",
    "Masters Thesis" => "fa-file-text-o",
    "MovingImage" => "fa-file-video-o",
    "Part of Book" => "fa-book",
    "PhysicalObject" => "fa-cube",
    "Poster" => "fa-picture-o",
    "Presentation" => "fa-file-powerpoint-o",
    "Project" => "fa-folder-open",
    "Report" => "fa-bar-chart",
    "Research Paper" => "fa-file-text-o",
    "Service" => "fa-cogs",
    "Software" => "fa-file-code-o",
    "Software or Program Code" => "fa-file-code-o",
    "Sound" => "fa-headphones",
    "StillImage" => "fa-picture-o",
    "Text" => "fa-file-text-o",
    "Video" => "fa-file-video-o"
  }.freeze
  IR_DEFAULT_RESOURCE_TYPE_ICON = "fa-file-o"

  def ir_resource_type_tiles(response, field)
    known = IR_RESOURCE_TYPE_ICONS.keys
    items = response.aggregations[field]&.items.to_a.select { |item| item.hits.positive? }
    items.each_with_index.sort_by { |item, i| [known.index(item.value) || known.size, i] }.map do |item, _i|
      { label: item.value,
        count: item.hits,
        icon: IR_RESOURCE_TYPE_ICONS.fetch(item.value, IR_DEFAULT_RESOURCE_TYPE_ICON),
        path: main_app.search_catalog_path(f: { field => [item.value] }) }
    end
  end
end
