# frozen_string_literal: true

module AccountCname
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    # @param [String] piece the tenant piece of the canonical name
    # @return [String] full canonical name
    # @raise [ArgumentError] if piece contains a trailing dot
    # @see Settings.multitenancy.default_host
    def default_cname(piece)
      return unless piece
      raise ArgumentError, "param '#{piece}' must not contain trailing dots" if piece =~ /\.\Z/
      # rubocop:disable Style/FormatStringToken
      default_host = Settings.multitenancy.default_host || "%{tenant}.#{admin_host}"
      # rubocop:enable Style/FormatStringToken
      canonical_cname(format(default_host, tenant: piece.parameterize))
    end

    # Canonicalize the account cname or request host for comparison
    # @param [String] cname distinct part of host name
    # @return [String] canonicalized host name
    def canonical_cname(cname)
      # DNS host names are case-insensitive. Trim trailing dot(s).
      cname &&= cname.downcase.sub(/\.*\Z/, '')
      cname
    end

    # @return [Account]
    def from_request(request)
      from_cname(request.host)
    end

    def from_cname(cname)
      joins(:domain_names).find_by(domain_names: { is_active: true, cname: canonical_cname(cname) })
    end
  end

  # Reader to convert old cname in to new domain name child object
  def cname
    self[:cname] || domain_names&.first&.canonicalize_cname
  end

  # Writer to convert old cname in to new domain name child object
  def cname=(value)
    self[:cname] = value
    domain_names.build(cname: value) unless domain_names.detect { |dn| dn.cname == value }
  end

  private

    def default_cname(piece = name)
      self.class.default_cname(piece)
    end
end
