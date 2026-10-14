# frozen_string_literal: true

# Reads a vocabulary's terms for its show page, and the digest that guards a reorder
# saved from that page.
#
# The two have to be read together. Read separately, the digest can describe a
# reorder the rows beside it never showed, and the save it guards would overwrite
# that reorder rather than refuse it — so both are taken under one lock.
#
# The lock is only worth taking for a page that will draw the reorder form. It is
# SELECT ... FOR UPDATE, and the digest reads every entry, so a page with no order to
# save — a depositor's, an imported copy's, a read-only yaml — would spend a full
# table read on nothing and queue behind a running import.
class ControlledVocabularyTermLoad
  attr_reader :terms, :state_digest, :presenter

  # @param entry [ControlledVocabularyCatalog::Entry]
  # @param can_manage [Boolean] whether this user may change the vocabulary
  def self.call(entry:, can_manage:)
    new(entry: entry, can_manage: can_manage).tap(&:read)
  end

  def initialize(entry:, can_manage:)
    @entry = entry
    @can_manage = can_manage
  end

  # @return [self]
  def read
    if locked?
      read_under_lock
    else
      @terms = terms_for_entry
    end

    @presenter = presenter_for(@terms)
    self
  end

  private

  # Asked before the terms are read, so it cannot depend on them.
  def locked?
    presenter_for(nil).controls_possible?
  end

  def read_under_lock
    @entry.vocabulary.with_lock do
      @terms = terms_for_entry
      @state_digest = @entry.vocabulary.term_state_digest
    end
  end

  def terms_for_entry
    ControlledVocabularyCatalog.terms_for(@entry)
  end

  def presenter_for(terms)
    Hyku::ControlledVocabularyTermsPresenter.new(entry: @entry, can_manage: @can_manage, terms: terms)
  end
end
