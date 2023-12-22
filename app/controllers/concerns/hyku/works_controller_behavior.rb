# frozen_string_literal: true

# OVERRIDE: Hyrax v5.0.0rc2 to add inject_show_theme_views - Hyku theming
#           and correct hostname of manifests
#           and to add Hyrax IIIF AV
module Hyku
  # include this module after including Hyrax::WorksControllerBehavior to override
  # Hyrax::WorksControllerBehavior methods with the ones defined here
  module WorksControllerBehavior
    extend ActiveSupport::Concern

    # Adds behaviors for hyrax-iiif_av plugin and provides #manifest and #iiif_manifest_builder
    include Hyrax::IiifAv::ControllerBehavior

    included do
      # add around action to load theme show page views
      around_action :inject_show_theme_views, except: :delete
    end

    def json_manifest
      iiif_manifest_builder.manifest_for(presenter: iiif_manifest_presenter)
    end

    private

    def iiif_manifest_presenter
      Hyrax::IiifManifestPresenter.new(search_result_document(id: params[:id])).tap do |p|
        p.hostname = request.hostname
        p.ability = current_ability
      end
    end

    def format_error_messages(errors)
      errors.messages.map do |field, messages|
        field_name = field.to_s.humanize
        messages.map { |message| "#{field_name} #{message.sub(/^./, &:downcase)}" }
      end.flatten.join("\n")
    end

    # Creating a form object that can re-render most of the submitted parameters.
    # Required for ActiveFedora::Base objects only.
    def rebuild_form(original_input_params_for_form)
      build_form
      @form = Hyrax::Forms::FailedSubmissionFormWrapper
              .new(form: @form,
                   input_params: original_input_params_for_form)
    end

    def after_update_error(errors)
      respond_to do |wants|
        wants.html do
          flash[:error] = format_error_messages(errors)
          build_form unless @form.is_a? Hyrax::ChangeSet
          render 'edit', status: :unprocessable_entity
        end
        wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: }) }
      end
    end

    def available_admin_sets
      # only returns admin sets in which the user can deposit
      admin_set_results = Hyrax::AdminSetService.new(self).search_results(:deposit)

      # get all the templates at once, reducing query load
      templates = Hyrax::PermissionTemplate.where(source_id: admin_set_results.map(&:id)).to_a

      admin_sets = admin_set_results.map do |admin_set_doc|
        template = templates.find { |temp| temp.source_id == admin_set_doc.id.to_s }

        ## OVERRIDE Hyrax v5.0.0rc2
        # Removes a short-circuit that allowed users with manage access to
        # the given permission_template to always be able to edit a record's sharing
        # (i.e. the "Sharing" tab in forms).
        #
        # We remove this because there is currently a bug in Hyrax where, if the
        # workflow does not allow access grants, changes to a record's sharing
        # are not being persisted, leading to a confusing UX.
        # @see https://github.com/samvera/hyrax/issues/5904
        #
        # TEMPORARY: This override should be removed when the bug is resolved in
        # upstream Hyrax and brought into this project.
        #
        # determine if sharing tab should be visible
        sharing = !!template&.active_workflow&.allows_access_grant?

        Hyrax::AdminSetSelectionPresenter::OptionsEntry
          .new(admin_set: admin_set_doc, permission_template: template, permit_sharing: sharing)
      end

      Hyrax::AdminSetSelectionPresenter.new(admin_sets:)
    end

    # added to prepend the show theme views into the view_paths
    def inject_show_theme_views
      if show_page_theme && show_page_theme != 'default_show'
        original_paths = view_paths
        Hyku::Application.theme_view_path_roots.each do |root|
          show_theme_view_path = File.join(root, 'app', 'views', "themes", show_page_theme.to_s)
          prepend_view_path(show_theme_view_path)
        end
        yield
        # rubocop:disable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
        # Do NOT change this line. This is calling the Rails view_paths=(paths) method and not a variable assignment.
        view_paths=(original_paths)
        # rubocop:enable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
      else
        yield
      end
    end
  end
end
