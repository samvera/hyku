# frozen_string_literal: true

module Qa::Authorities
  class Mesh < Qa::Authorities::Base
    def initialize(subauthority = nil)
      @subauthority = subauthority
    end

    def search(q, _controller)
      return [] if q.blank?

      # Search the local MeSH authority entries
      mesh_authority = Qa::LocalAuthority.find_by(name: 'mesh')
      return [] unless mesh_authority

      # Search for terms that contain the query string (case-insensitive)
      entries = mesh_authority.local_authority_entries
                              .where("label ILIKE ?", "%#{q}%")
                              .limit(20)
                              .order(:label)

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
