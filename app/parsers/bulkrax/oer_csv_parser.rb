# frozen_string_literal: true

module Bulkrax
  module OerCsvParser
    # TODO(bkiahstroud): need a spec for this method, or the 4 methods it calls
    def create_memberships
      create_previous_version_relationships
      create_newer_version_relationships
      create_alternate_version_relationships
      create_related_item_relationships
    end

    def create_previous_version_relationships
      records_with_previous_versions.each do |record_id, previous_version_ids|
        record_with_previous_version = find_entry(record_id)

        # not finding the entries here indicates that the given identifiers are incorrect
        previous_versions = previous_version_ids.map do |identifier|
          find_entry(identifier)
        end.compact.uniq

        create_relationships(record_with_previous_version, previous_versions, previous_version_ids, 'previous-version')
      end
      status_info
    end

    def create_newer_version_relationships
      records_with_newer_versions.each do |record_id, newer_version_ids|
        record_with_newer_version = find_entry(record_id)

        # not finding the entries here indicates that the given identifiers are incorrect
        newer_versions = newer_version_ids.map do |identifier|
          find_entry(identifier)
        end.compact.uniq

        create_relationships(record_with_newer_version, newer_versions, newer_version_ids, 'newer-version')
      end
      status_info
    end

    def create_alternate_version_relationships
      records_with_alternate_versions.each do |record_id, alternate_version_ids|
        record_with_alternate_version = find_entry(record_id)

        # not finding the entries here indicates that the given identifiers are incorrect
        alternate_versions = alternate_version_ids.map do |identifier|
          find_entry(identifier)
        end.compact.uniq

        create_relationships(record_with_alternate_version, alternate_versions, alternate_version_ids, 'alternate-version')
      end
      status_info
    end

    def create_related_item_relationships
      records_with_related_items.each do |record_id, related_item_ids|
        record_with_related_item = find_entry(record_id)

        # not finding the entries here indicates that the given identifiers are incorrect
        related_items = related_item_ids.map do |identifier|
          find_entry(identifier)
        end.compact.uniq

        create_relationships(record_with_related_item, related_items, related_item_ids, 'related-item')
      end
      status_info
    end

    # TODO(bkiahstroud): needs specs
    def create_relationships(record_with_relationship, related_members, related_member_ids, relationship_type)
      if record_with_relationship.present? && (related_members.length != related_member_ids.length)
        # Increment the failures for the number we couldn't find
        # Because all of our entries have been created by now, if we can't find them, the data is wrong
        Rails.logger.error("Expected #{related_member_ids.length} related_members for record_with_relationship entry #{record_with_relationship.id}, found #{related_members.length}")
        return if related_members.empty?
        Rails.logger.warn("Adding #{related_members.length} related_members to record_with_relationship entry #{record_with_relationship.id} (expected #{related_member_ids.length})")
      end

      record_with_relationship_id = record_with_relationship.id
      related_item_entry_ids = related_members.map(&:id)
      RelatedMembershipsJob.perform_later(record_with_relationship_id, related_item_entry_ids, relationship_type)
    rescue StandardError => e
      status_info(e)
    end

    def records_with_previous_versions
      setup_records_with(:previous_version)
    end

    def records_with_newer_versions
      setup_records_with(:newer_version)
    end

    def records_with_alternate_versions
      setup_records_with(:alternate_version)
    end

    def records_with_related_items
      setup_records_with(:related_item)
    end

    private

    # Will be skipped unless the #record is a Hash
    # rubocop:disable Metrics/MethodLength
    def setup_records_with(relationship_type)
      records_with_relationship = []

      records.each do |record|
        r = if record.respond_to?(:to_h)
              record.to_h
            else
              record
            end
        next unless r.is_a?(Hash)

        related_member_ids = if r[relationship_type].is_a?(String)
                               r[relationship_type].split(/\s*[:;|]\s*/) # TODO(bkiahstroud): use Bulkrax::ApplicationMatcher#result to process split
                             else
                               r[relationship_type]
                             end
        next if related_member_ids.blank?

        records_with_relationship << {
          r[:source_identifier] => related_member_ids
        }
      end
      records_with_relationship.blank? ? records_with_relationship : records_with_relationship.inject(:deep_merge)
    end

    def find_entry(identifier)
      entry_class.where(
        identifier:,
        importerexporter_id: importerexporter.id,
        importerexporter_type: 'Bulkrax::Importer'
      ).first
    end
  end
end
