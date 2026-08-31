# frozen_string_literal: true

module Hyku
  # Answers what the terms panel of a vocabulary's show page may offer, so the
  # controller and the view ask the same question of the same object.
  #
  # The controller needs the answer before the view does: reading the terms under a
  # lock, and digesting them, is only worth doing for a page that will draw the
  # reorder form. Asking here rather than in each place keeps the work the controller
  # does and the controls the view renders from drifting apart.
  class ControlledVocabularyTermsPresenter
    STATUS_KEYS = { active: 'active', inactive: 'inactive', unknown: 'status_unknown' }.freeze

    attr_reader :entry, :terms

    # @param entry [ControlledVocabularyCatalog::Entry]
    # @param can_manage [Boolean] whether this user may change the vocabulary
    # @param terms [Array<Hash>, nil] loaded terms; nil until they are read
    def initialize(entry:, can_manage:, terms: nil)
      @entry = entry
      @can_manage = can_manage
      @terms = terms
    end

    # Whether the page could offer a control at all, answerable before the terms are
    # read. The controller gates the locked read on this, so it must not depend on
    # them.
    def controls_possible?
      entry.editable? && @can_manage
    end

    # Retiring needs a row to write and the right to change it.
    def togglable?
      controls_possible? && terms.present?
    end

    # Reordering needs those and something to move as well: a single term has no
    # order to put it in.
    def reorderable?
      togglable? && terms.many?
    end

    # :active, :inactive, or :unknown for a term that never states one. Unknown is
    # kept distinct from active so a yaml term that omits the column reads as
    # unstated rather than as a claim nobody made — Hyrax still treats it as usable.
    #
    # Read the way Hyrax::AuthorityService#select_active_options reads it, so the
    # badge cannot disagree with what the deposit form offers.
    def status_of(term)
      return :unknown if term['active'].nil?

      term.fetch('active', true) ? :active : :inactive
    end

    # Whether the button offers to retire the term rather than restore it.
    def retiring?(term)
      status_of(term) != :inactive
    end

    def status_label(term)
      I18n.t("hyku.admin.controlled_vocabulary.#{STATUS_KEYS.fetch(status_of(term))}")
    end

    # Only a retired term is emphasized; the rest stay muted.
    def status_variant(term)
      status_of(term) == :inactive ? 'badge-secondary' : 'badge-quiet'
    end

    # These two name their term because a screen reader meets the buttons out of the
    # context of the row they sit in.
    def reorder_handle_label(term)
      I18n.t('hyku.admin.controlled_vocabulary.reorder_handle', label: term['label'])
    end

    def move_label(term, direction)
      key = direction.negative? ? 'move_earlier' : 'move_later'
      I18n.t("hyku.admin.controlled_vocabulary.#{key}", label: term['label'])
    end

    def toggle_variant(term)
      retiring?(term) ? 'btn-outline-secondary' : 'btn-outline-primary'
    end

    def toggle_label(term)
      I18n.t("hyku.admin.controlled_vocabulary.#{retiring?(term) ? 'retire' : 'restore'}")
    end

    def toggle_value(term)
      retiring?(term) ? 'false' : 'true'
    end
  end
end
