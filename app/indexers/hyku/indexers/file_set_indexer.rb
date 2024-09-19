# frozen_string_literal: true

module Hyku
  module Indexers
    class FileSetIndexer < Hyrax::Indexers::FileSetIndexer
      include Hyrax::Indexer(:bulkrax_metadata)
      include Hyrax::Indexer(:hyku_file_set_metadata)

      def to_solr
        return super unless Flipflop.default_pdf_viewer?

        super.tap do |solr_doc|
          solr_doc['all_text_timv'] = solr_doc['all_text_tsimv'] = pdf_text
        end
      end

      private

      # rubocop:disable Metrics/MethodLength
      def pdf_text
        return unless resource.original_file&.pdf?
        return unless resource.original_file&.content.is_a? String

        begin
          text = IO.popen(['pdftotext', '-', '-'], 'r+b') do |pdftotext|
            pdftotext.write(resource.original_file.content)
            pdftotext.close_write
            pdftotext.read
          end

          text.tr("\n", ' ')
              .squeeze(' ')
              .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') # remove non-UTF-8 characters
        rescue Errno::ENOENT => e
          raise e unless e.message.include?("No such file or directory - pdftotext")
          Rails.logger.warn("`pdfinfo' is not installed; unable to extract text from the PDF's content")
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
