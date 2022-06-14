# frozen_string_literal: true

# OVERRIDE FROM HYRAX 2.5.1 TO ONLY ESCAPE URLS THAT ARE UNSAFE

module Hyrax
  module Actors
    # If there is a key `:remote_files' in the attributes, it attaches the files at the specified URIs
    # to the work. e.g.:
    #     attributes[:remote_files] = filenames.map do |name|
    #       { url: "https://example.com/file/#{name}", file_name: name }
    #     end
    #
    # Browse everything may also return a local file. And although it's in the
    # url property, it may have spaces, and not be a valid URI.
    class CreateWithRemoteFilesActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        remote_files = env.attributes.delete(:remote_files)
        next_actor.create(env) && attach_files(env, remote_files)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        remote_files = env.attributes.delete(:remote_files)
        next_actor.update(env) && attach_files(env, remote_files)
      end

      private

        def make_pdfs(env)
          ConvertImagesToPdfJob.set(wait: 2.minutes).perform_later(env.curation_concern)
        end

        def whitelisted_ingest_dirs
          Hyrax.config.whitelisted_ingest_dirs
        end

        # @param uri [URI] the uri fo the resource to import
        def validate_remote_url(uri)
          if uri.scheme == 'file'
            path = File.absolute_path(CGI.unescape(uri.path))
            whitelisted_ingest_dirs.any? do |dir|
              path.start_with?(dir) && path.length > dir.length
            end
          else
            # TODO: It might be a good idea to validate other URLs as well.
            #       The server can probably access URLs the user can't.
            true
          end
        end

        # OVERRIDE FROM HYRAX 2.5.1 - only escape uri if unsafe, follows redirects to get final url
        # @param [HashWithIndifferentAccess] remote_files
        # @return [TrueClass]
        def attach_files(env, remote_files)
          return true unless remote_files
          # URI::UNSAFE except skips % sign. This allows for already encoded urls to pass
          safety_regex = %r{/[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]\%]/}
          remote_files.each do |file_info|
            next if file_info.blank? || file_info[:url].blank?
            # follow redirects to get final redirect url
            # rubocop:disable Metrics/LineLength
            url = (file_info[:url]&.match(/^file:/) ? file_info[:url] : FinalRedirectUrl.final_redirect_url(file_info[:url]))
            # rubocop:enable Metrics/LineLength
            uri = if url.match(safety_regex).present?
                    # Escape any space characters, so that this is a legal URI
                    URI.parse(Addressable::URI.escape(url))
                  else
                    URI.parse(url)
                  end

            unless validate_remote_url(uri)
              # rubocop:disable LineLength
              Rails.logger.error "User #{env.user.user_key} attempted to ingest file from url #{file_info[:url]}, which doesn't pass validation"
              # rubocop:enable LineLength
              return false
            end
            auth_header = file_info.fetch(:auth_header, {})
            create_file_from_url(env, uri, file_info[:file_name], auth_header)
            if display_pdfs_in_uv?
              ConvertRemotePdfToJpgJob.perform_now(uri.to_s, env.curation_concern, env.attributes, env.user)
            end
          end

          works_that_need_pdfs = [Image, GenericWork]
          make_pdfs(env) if works_that_need_pdfs.include?(env.curation_concern.class) && Flipflop.show_pdfs_in_uv?
          true
        end
        # rubocop:enable Metrics/PerceivedComplexity

        # Generic utility for creating FileSet from a URL
        # Used in to import files using URLs from a file picker like browse_everything
        def create_file_from_url(env, uri, file_name, auth_header = {})
          ::FileSet.new(import_url: uri.to_s, label: file_name) do |fs|
            actor = Hyrax::Actors::FileSetActor.new(fs, env.user)
            actor.create_metadata(visibility: env.curation_concern.visibility)
            actor.attach_to_work(env.curation_concern)
            fs.save!
            if uri.scheme == 'file'
              # Turn any %20 into spaces.
              file_path = CGI.unescape(uri.path)
              IngestLocalFileJob.perform_later(fs, file_path, env.user)
            else
              ImportUrlJob.perform_later(fs, operation_for(user: actor.user), auth_header)
            end
          end
        end

        def operation_for(user:)
          Hyrax::Operation.create!(user: user,
                                   operation_type: "Attach Remote File")
        end
    end
  end
end
