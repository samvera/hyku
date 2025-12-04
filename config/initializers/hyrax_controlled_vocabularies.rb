# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Hyrax
  module ControlledVocabularies
    # rubocop:disable Metrics/ClassLength
    class << self
      def controlled_vocab_mappings
        {
          'audience' => 'audience',
          'discipline' => 'discipline',
          'education_level' => 'education_levels',
          'learning_resource_type' => 'learning_resource_types',
          'license' => 'licenses',
          'resource_type' => 'resource_types',
          'rights_statement' => 'rights_statements'
        }.freeze
      end

      def services
        {
          'audience' => 'Hyrax::AudienceService',
          'discipline' => 'Hyrax::DisciplineService',
          'education_levels' => 'Hyrax::EducationLevelsService',
          'learning_resource_types' => 'Hyrax::LearningResourceTypesService',
          'oer_types' => 'Hyrax::OerTypesService',
          'licenses' => 'Hyrax::LicenseService',
          'resource_types' => 'Hyrax::ResourceTypesService',
          'rights_statements' => 'Hyrax::RightsStatementService'
        }.freeze
      end

      def remote_authorities
        {
          'loc/subjects' => {
            url: "/authorities/search/loc/subjects",
            type: 'autocomplete'
          },
          'loc/names' => {
            url: "/authorities/search/loc/names",
            type: 'autocomplete'
          },
          'loc/genre_forms' => {
            url: "/authorities/search/loc/genreForms",
            type: 'autocomplete'
          },
          'loc/countries' => {
            url: "/authorities/search/loc/countries",
            type: 'autocomplete'
          },
          'loc/languages' => {
            url: "/authorities/search/loc/languages",
            type: 'autocomplete'
          },
          'loc/iso639-1' => {
            url: "/authorities/search/loc/iso639-1",
            type: 'autocomplete'
          },
          'loc/iso639-2' => {
            url: "/authorities/search/loc/iso639-2",
            type: 'autocomplete'
          },
          'getty/aat' => {
            url: "/authorities/search/getty/aat",
            type: 'autocomplete'
          },
          'getty/tgn' => {
            url: "/authorities/search/getty/tgn",
            type: 'autocomplete'
          },
          'getty/ulan' => {
            url: "/authorities/search/getty/ulan",
            type: 'autocomplete'
          },
          'geonames' => {
            url: "/authorities/search/geonames",
            type: 'autocomplete'
          },
          'fast' => {
            url: "/authorities/search/assign_fast/topical",
            type: 'autocomplete'
          },
          'fast/all' => {
            url: "/authorities/search/assign_fast/all",
            type: 'autocomplete'
          },
          'fast/personal' => {
            url: "/authorities/search/assign_fast/personal",
            type: 'autocomplete'
          },
          'fast/corporate' => {
            url: "/authorities/search/assign_fast/corporate",
            type: 'autocomplete'
          },
          'fast/geographic' => {
            url: "/authorities/search/assign_fast/geographic",
            type: 'autocomplete'
          },
          'mesh' => {
            url: "/authorities/search/local/mesh",
            type: 'autocomplete'
          },
          'discogs' => {
            url: "/authorities/search/discogs/all",
            type: 'autocomplete'
          },
          'discogs/release' => {
            url: "/authorities/search/discogs/release",
            type: 'autocomplete'
          },
          'discogs/master' => {
            url: "/authorities/search/discogs/master",
            type: 'autocomplete'
          }
        }.freeze
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
# rubocop:enable Metrics/ModuleLength
