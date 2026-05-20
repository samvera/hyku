# frozen_string_literal: true

module Qa::Authorities
  class Mesh < Qa::Authorities::Base
    MAX_AUTOCOMPLETE_RESULTS = 20

    def initialize(subauthority = nil)
      @subauthority = subauthority
    end

    def search(q, _controller)
      return [] if q.blank?

      mesh_authority = Qa::LocalAuthority.find_by(name: 'mesh')
      return [] unless mesh_authority

      q_down = q.downcase
      entries = mesh_authority.local_authority_entries
                              .where("LOWER(label) LIKE ?", "%#{q_down}%")
                              .order(Arel.sql(ActiveRecord::Base.sanitize_sql_array([
                                                                                      "CASE WHEN LOWER(label) = ? THEN 0 " \
                                                                                      "WHEN LOWER(label) LIKE ? THEN 1 ELSE 2 END, label ASC",
                                                                                      q_down, "#{q_down}%"
                                                                                    ])))
                              .limit(MAX_AUTOCOMPLETE_RESULTS)

      entries.map do |entry|
        {
          id: entry.uri.presence || entry.label,
          label: entry.label,
          value: entry.label
        }
      end
    end
  end
end
