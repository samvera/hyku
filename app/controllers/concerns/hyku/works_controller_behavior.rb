# frozen_string_literal: true

# OVERRIDE: Hyrax v5.0.0rc2 to:
#           - add inject_show_theme_views - Hyku theming
#           - correct hostname of manifests
#           - override for bug https://github.com/samvera/hyrax/issues/5904
#           - use Hyku::WorkShowPresenter rather than Hyrax's presenter
#           - refuse a parent_id the depositor cannot edit or whose type cannot
#             contain the work being created
module Hyku
  # include this module after including Hyrax::WorksControllerBehavior to override
  # Hyrax::WorksControllerBehavior methods with the ones defined here
  module WorksControllerBehavior
    extend ActiveSupport::Concern

    included do
      # add around action to load theme show page views
      around_action :inject_show_theme_views, except: :delete
      before_action :ensure_parent_accepts_child, only: :create
      self.show_presenter = Hyku::WorkShowPresenter

      # These cache wrapper methods need to be in the top level so that they override other modules
      def show
        return super if Rails.env.test?
        fresh_when presenter
        expires_in 1.hour, public: true
        super
      end

      def manifest
        return super if Rails.env.test?
        fresh_when iiif_manifest_presenter
        expires_in 1.hour, public: true
        super
      end
    end

    def json_manifest
      iiif_manifest_builder.manifest_for(presenter: iiif_manifest_presenter)
    end

    private

    # parent_id reaches Steps::AddToParent straight from params, and that step
    # validates neither the type pairing nor the user's access to the parent.
    #
    # Read from Solr, not the persistence layer: only the parent's id and class are
    # needed, and AddToParent loads the resource itself.
    def ensure_parent_accepts_child
      parent_id = params[:parent_id]
      return if parent_id.blank?

      parent = ::SolrDocument.find(parent_id)
      # Normalize both sides: valid_child_concerns holds the ActiveFedora classes
      # while curation_concern_type is the Valkyrie resource, so comparing class
      # names directly never matches and would reject every legitimate create.
      child_types = Hyrax::ModelRegistry.rdf_representations_from(
        Hyrax::ChildTypes.for(parent: parent.hydra_model).to_a
      )
      child_type = Hyrax::ModelRegistry.rdf_representations_from([self.class.curation_concern_type]).first
      return if current_ability.can?(:edit, parent) && child_types.include?(child_type)

      reject_parent
    rescue Blacklight::Exceptions::RecordNotFound, Valkyrie::Persistence::ObjectNotFoundError
      reject_parent
    end

    def reject_parent
      redirect_to main_app.root_path, alert: I18n.t('hyku.works.errors.parent_not_allowed')
    end

    def iiif_manifest_presenter
      Hyrax::IiifManifestPresenter.new(search_result_document(id: params[:id])).tap do |p|
        p.hostname = request.hostname
        p.ability = current_ability
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
