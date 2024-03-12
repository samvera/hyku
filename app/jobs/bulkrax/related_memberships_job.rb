# frozen_string_literal: true

# TODO(bkiahstroud): needs spec - see Bulkrax's child_relationships_job_spec for inspiration
module Bulkrax
  class RelatedMembersError < RuntimeError; end

  class RelatedMembershipsJob < ApplicationJob
    queue_as :import

    def perform(*args)
      @record_with_relationship_id = args[0]
      @related_item_entry_ids = args[1]
      @relationship_type = args[2]

      related_membership
    rescue Bulkrax::RelatedMembersError # Not all of the Works exist yet; reschedule
      reschedule(@record_with_relationship_id, @related_item_entry_ids, @relationship_type)
    end

    private

    # add related works to work
    def related_membership
      related_members = []

      related_works_hash.each { |k, _v| related_members << k }
      relate_members_to_record(related_members) if related_members.present?
    end

    ## Work-Work membership is added to the record as related_members
    # @param [Array] related_members: id(s) of Work object(s) that are related to the record
    def relate_members_to_record(related_members)
      # build related_members_attributes
      attrs = {
        id: entry&.factory&.find&.id,
        related_members_attributes: related_members.each.each_with_object({}) do |related_member, ids|
          # NOTE(bkiahstroud): generate random string for index; using a traditional index causes issues
          ids[SecureRandom.alphanumeric(15)] = { id: related_member, relationship: @relationship_type }
        end
      }

      Bulkrax::RelatedMemberObjectFactory.new(attrs, entry.identifier, false, user, entry.factory_class).run
    rescue StandardError => e
      entry.status_info(e)
      entry.save!
    end

    ##
    # @return [Hash] id of Work object with nested hash of the Work's source_identifier
    def related_works_hash
      @related_works_hash ||= related_member_entries.each_with_object({}) do |related_member_entry, hash|
        work = related_member_entry.factory.find
        # If we can't find the Work, raise a custom error
        raise RelatedMembersError if work.blank?
        hash[work.id] = { source_identifier: related_member_entry.identifier }
      end
    end

    # @return [Array] of entries to relate to the record
    def related_member_entries
      @related_member_entries ||= @related_item_entry_ids.map { |e| Bulkrax::Entry.find(e) }
    end

    ##
    # @return [Bulkrax::Entry] of the record
    def entry
      @entry ||= Bulkrax::Entry.find(@record_with_relationship_id)
    end

    def user
      @user ||= entry.importerexporter.user
    end

    def reschedule(record_with_relationship_id, related_member_entry_ids, relationship_type)
      RelatedMembershipsJob
        .set(wait: 5.minutes)
        .perform_later(record_with_relationship_id, related_member_entry_ids, relationship_type)
    end
  end
end
