# frozen_string_literal: true

# A module to define abilities related to controlled vocabularies.
#
# Viewing is granted to anyone who can deposit, because a depositor needs to see
# the terms a field offers and which of them are retired. Managing is restricted
# to admins: a vocabulary's terms are the values works store, so editing one
# affects every work already citing it.
module Hyrax
  module Ability
    module ControlledVocabularyAbility
      # +view+ is the action the dashboard checks; +read+ is granted alongside it
      # because CanCan does not alias the two, and Hyrax callers reach for :read.
      def controlled_vocabulary_abilities
        can %i[manage view read], :controlled_vocabularies if admin?

        # Same check Bulkrax uses to gate importing, so anyone who can deposit
        # through it can also look up the vocabularies behind those fields.
        can %i[view read], :controlled_vocabularies if can_import_works?
      end
    end
  end
end
