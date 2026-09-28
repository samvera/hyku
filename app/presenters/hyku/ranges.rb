# frozen_string_literal: true

module Hyku
  module Ranges
    def file_set_presenters(seen: Set.new)
      return super() unless Flipflop.iiif_ranges?
      return [] unless seen.add?(id.to_s)

      member_presenters.flat_map do |member|
        if member.work?
          member.file_set_presenters(seen: seen)
        elsif displayable_file_set?(member)
          member.item_metadata = item_metadata
          [member]
        else
          []
        end
      end
    end

    def member_presenters
      @member_presenters ||= super.each { |p| p.try(:base_url=, base_url) }
    end

    def item_metadata
      @item_metadata ||= manifest_metadata
    end

    def ranges
      return [] unless Flipflop.iiif_ranges?
      return [] if child_work_presenters.empty?

      [::IIIFManifest::ManifestRange.new(label: Array(title).first || '',
                                         file_set_presenters: [],
                                         ranges: member_ranges(seen: Set.new([id.to_s])))]
    end

    def manifest_range(seen: Set.new)
      return unless seen.add?(id.to_s)

      ::IIIFManifest::ManifestRange.new(label: Array(title).first || '',
                                        file_set_presenters: member_presenters.select { |p| displayable_file_set?(p) },
                                        ranges: child_work_presenters.filter_map { |p| p.manifest_range(seen: seen) })
    end

    def member_ranges(seen: Set.new)
      member_presenters.filter_map do |member|
        if member.work?
          member.manifest_range(seen: seen)
        elsif displayable_file_set?(member)
          ::IIIFManifest::ManifestRange.new(label: member.to_s, file_set_presenters: [member], ranges: [])
        end
      end
    end

    def work_presenters
      Flipflop.iiif_ranges? ? [] : super
    end

    def child_work_presenters
      member_presenters.select(&:work?)
    end

    def version(seen: Set.new)
      own_version = super()
      return own_version unless Flipflop.iiif_ranges?
      return '' unless seen.add?(id.to_s)

      ['child_works', own_version, *child_work_presenters.map { |p| p.version(seen: seen) }].join('|')
    end

    private

    def displayable_file_set?(presenter)
      presenter.file_set? && (presenter.display_image || presenter.display_content)
    end
  end
end
