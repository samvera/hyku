# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2
# - Fix file upload in logo and banner
# - Use work titles for collection thumbnail select & to add an option to reset to the default thumbnail
module Hyrax
  module Dashboard
    ## Shows a list of all collections to the admins
    # rubocop:disable Metrics/ModuleLength
    module CollectionsControllerDecorator
      def edit
        form
        collection_type
        # Gets original filename of an uploaded thumbnail. See #update
        return unless ::SolrDocument.find(@collection.id).thumbnail_path.include?("uploaded_collection_thumbnails") && uploaded_thumbnail?
        @thumbnail_filename = File.basename(uploaded_thumbnail_files.reject { |f| File.basename(f).include? @collection.id }.first)
      end

      def uploaded_thumbnail?
        uploaded_thumbnail_files.any?
      end

      def uploaded_thumbnail_files
        Dir["#{UploadedCollectionThumbnailPathService.upload_dir(@collection)}/*"]
      end

      def update
        # OVERRIDE: ensure user is allowed to change visibility
        authorize! :manage_discovery, @collection if collection_params[:visibility].present? && @collection.visibility != collection_params[:visibility]

        super
      end

      def process_branding
        super

        # TODO: does this still work?
        process_uploaded_thumbnail(params[:collection][:thumbnail_upload]) if params[:collection][:thumbnail_upload]
      end

      # Deletes any previous thumbnails. The thumbnail indexer (see services/hyrax/indexes_thumbnails)
      # checks if an uploaded thumbnail exists in the public folder before indexing the thumbnail path.
      def delete_uploaded_thumbnail
        FileUtils.rm_rf(uploaded_thumbnail_files)
        @collection.update_index

        respond_to do |format|
          format.html
          format.js # renders delete_uploaded_thumbnail.js.erb, which updates _current_thumbnail.html.erb
        end
      end

      # Renders a JSON response with a list of files in this collection
      # This is used by the edit form to populate the thumbnail_id dropdown
      # OVERRIDE: Hyrax 2.9 to use work titles for collection thumbnail select & to add an option to reset to the default thumbnail
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def files
        params[:q] = '' unless params[:q]
        builder = Hyrax::CollectionMemberSearchBuilder.new(scope: self, collection:, search_includes_models: :works)
        # get the default work image because we do not want to show any works in this
        # dropdown that only have the default work image. this indicates that they have
        # no files attached, and will throw an error if selected.
        default_work_thumbnail_path = Site.instance.default_work_image&.url.presence || ActionController::Base.helpers.image_path('default.png')
        work_with_no_files_thumbnail_path = ActionController::Base.helpers.image_path('work.png')
        response = repository.search(builder.where(params[:q]).query)
        # only return the works that have files, because these will be the only ones with a viable thumbnail
        result = response.documents.reject do |document|
                   document["thumbnail_path_ss"].blank? || document["thumbnail_path_ss"].include?(default_work_thumbnail_path) ||
                     document["thumbnail_path_ss"].include?(work_with_no_files_thumbnail_path)
                   # rubocop:disable Style/MultilineBlockChain
                 end.map do |document|
          # rubocop:enable Style/MultilineBlockChain
          { id: document["thumbnail_path_ss"].split('/').last.gsub(/\?.*/, ''), text: document["title_tesim"].first }
        end
        reset_thumbnail_option = {
          id: '',
          text: 'Default thumbnail'
        }
        result << reset_thumbnail_option
        render json: result
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      private

      # branding specific methods
      def process_banner_input
        return update_existing_banner if params["banner_unchanged"] == "true"
        remove_banner
        uploaded_file_ids = params["banner_files"]
        banner_text = params["banner_text"]&.first
        add_new_banner(uploaded_file_ids, banner_text) if uploaded_file_ids
      end

      def update_existing_banner
        banner_info = CollectionBrandingInfo.where(collection_id: @collection.id.to_s).where(role: "banner")
        banner_info.first.alt_text = params["banner_text"].first
        banner_info.first.save(banner_info.first.local_path, false)
      end

      def add_new_banner(uploaded_file_ids, banner_text)
        f = uploaded_files(uploaded_file_ids).first
        ## OVERRIDE Hyrax v5.0.0rc2 - process locations
        file_location = process_file_location(f)

        banner_info = CollectionBrandingInfo.new(
          collection_id: @collection.id,
          filename: File.split(f.file_url).last,
          role: "banner",
          alt_txt: banner_text,
          target_url: ""
        )
        ## OVERRIDE Hyrax v5.0.0rc2 - process locations
        banner_info.save file_location
      end

      def create_logo_info(uploaded_file_id, alttext, linkurl)
        file = uploaded_files(uploaded_file_id)
        file_location = process_file_location(file) # OVERRIDE Hyrax v5.0.0rc2 to clean file location

        logo_info = CollectionBrandingInfo.new(
          collection_id: @collection.id,
          filename: File.split(file.file_url).last,
          role: "logo",
          alt_txt: alttext,
          target_url: linkurl
        )
        logo_info.save file_location
        logo_info
      end

      def collection_params
        if Hyrax.config.collection_class < ActiveFedora::Base
          @participants = extract_old_style_permission_attributes(params[:collection])
          form_class.model_attributes(params[:collection])
        else
          params.permit(collection: {})[:collection]
                .merge(params.permit(:collection_type_gid)
              .with_defaults(collection_type_gid: default_collection_type_gid))
                .merge(member_of_collection_ids: Array(params[:parent_id]))
        end
      end

      # rubocop:disable Metrics/MethodLength
      def process_uploaded_thumbnail(uploaded_file)
        dir_name = UploadedCollectionThumbnailPathService.upload_dir(@collection)
        saved_file = Rails.root.join(dir_name, uploaded_file.original_filename)
        # Create directory if it doesn't already exist
        if File.directory?(dir_name) # clear contents
          delete_uploaded_thumbnail
        else
          FileUtils.mkdir_p(dir_name)
        end
        File.open(saved_file, 'wb') do |file|
          file.write(uploaded_file.read)
        end
        image = MiniMagick::Image.open(saved_file)
        # Save two versions of the image: one for homepage feature cards and one for regular thumbnail
        image.resize('500x900').format("jpg").write("#{dir_name}/#{@collection.id}_card.jpg")
        image.resize('150x300').format("jpg").write("#{dir_name}/#{@collection.id}_thumbnail.jpg")
        File.chmod(0o664, "#{dir_name}/#{@collection.id}_thumbnail.jpg")
        File.chmod(0o664, "#{dir_name}/#{@collection.id}_card.jpg")
      end
      # rubocop:enable Metrics/MethodLength

      ## OVERRIDE Hyrax v5.0.0rc2 handle file locations
      def process_file_location(f)
        if /^http/.match?(f.file_url)
          f.file.download!(f.file_url)
          f.file_url
        elsif %r{^\/}.match?(f.file_url)
          f.file.path
        else
          f.file_url
        end
      end
      ## END OVERRIDE
    end
  end
end

Hyrax::Dashboard::CollectionsController.prepend(Hyrax::Dashboard::CollectionsControllerDecorator)
