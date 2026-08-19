# frozen_string_literal: true

module Qa::Authorities
  class LocalVocabulary < Qa::Authorities::Local::TableBasedAuthority
    # Point Qa's startup index check at the lower(label) index we actually have.
    self.table_index = 'index_qa_local_authority_entries_on_lower_label_trgm'

    # Staff own these terms: they are whatever this tenant put in the tables, or the
    # yaml this application ships. Nothing external overwrites them.
    def locally_owned?
      true
    end

    def all
      return file_based.all if file_based?

      output_set(base_relation.ordered.limit(1000))
    end

    def find(uri)
      return file_based.find(uri) if file_based?

      record = base_relation.find_by(uri:)
      return {} unless record

      output(record)
    end

    def search(q)
      return file_based.search(q) if file_based?

      super
    end

    private

    # Decided per call, since one tenant can be seeded while another is not.
    def file_based?
      local_authority.nil?
    end

    def file_based
      Qa::Authorities::Local::FileBasedAuthority.new(subauthority)
    end

    def output(item)
      { id: item.uri, label: item.label, term: item.label, active: item.active }.with_indifferent_access
    end
  end
end
