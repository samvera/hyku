# frozen_string_literal: true

module Hyrax
  module Dashboard
    # Lists every authority a metadata profile can cite, so staff can find the source
    # key to paste into one, and creates the vocabularies this tenant manages.
    class ControlledVocabulariesController < ApplicationController
      with_themed_layout 'dashboard'

      before_action -> { authorize! :view, :controlled_vocabularies }, only: %i[index show]
      before_action -> { authorize! :manage, :controlled_vocabularies }, only: %i[new create]

      def index
        @controlled_vocabularies = ControlledVocabularyCatalog.all
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), request.path
      end

      def show
        @entry = ControlledVocabularyCatalog.find!(params[:id])

        respond_to do |format|
          format.html { show_page }
          format.csv { download :csv }
          format.yaml { download :yml }
        end
      end

      # Prefilled when the review step sends its values back, so correcting a typo
      # there does not mean retyping the rest.
      def new
        @controlled_vocabulary = Qa::LocalAuthority.new(prefill_params)
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        add_breadcrumb t('hyku.admin.controlled_vocabulary.new_title'), main_app.new_controlled_vocabulary_path
      end

      # Creation is a two-step process so the entry can be confirmed since there is no delete option.
      def create
        @controlled_vocabulary = Qa::LocalAuthority.new(controlled_vocabulary_params
                                                          .merge(staff_created: true))

        return redisplay_form unless @controlled_vocabulary.valid?
        return confirm_creation unless confirmed?
        return redisplay_form unless save_vocabulary

        redirect_to main_app.controlled_vocabulary_path(@controlled_vocabulary.name),
                    notice: t('hyku.admin.controlled_vocabulary.created',
                              name: @controlled_vocabulary.display_label)
      end

      private

      def show_page
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        # main_app, not the bare helper: this controller is namespaced under
        # Hyrax::, so bare url helpers resolve against the Hyrax engine, which does
        # not define this route. The engine's `/files/:id` then swallows it.
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        add_breadcrumb @entry.label, request.path
        @terms = ControlledVocabularyCatalog.terms_for(@entry)
        @usage = ControlledVocabularyUsage.citing(@entry.source_key)
        render :show
      end

      def download(format)
        raise ActiveRecord::RecordNotFound, "No terms to export for #{@entry.source_key}" unless @entry.downloadable?

        export = ControlledVocabularyExport.new(@entry)
        response.set_header('Content-Disposition', "attachment; filename=\"#{export.filename(format)}\"")
        self.response_body = export.public_send(format)
      end

      # Cast rather than tested for presence: the row cannot be deleted once written,
      # so `confirmed=` or `confirmed=false` has to mean not confirmed.
      def confirmed?
        ActiveModel::Type::Boolean.new.cast(params[:confirmed]).present?
      end

      # The unique index is what actually settles a collision: the review step invites
      # a re-submit, so two confirmations of one name can both pass validation and
      # only one can insert.
      def save_vocabulary
        @controlled_vocabulary.save
      rescue ActiveRecord::RecordNotUnique
        @controlled_vocabulary.errors.add(:name, :taken_as_source_key,
                                          value: @controlled_vocabulary.name)
        false
      end

      def confirm_creation
        creation_breadcrumbs
        render :confirm
      end

      def redisplay_form
        creation_breadcrumbs
        render :new, status: :unprocessable_entity
      end

      def creation_breadcrumbs
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t('hyku.admin.controlled_vocabularies'), main_app.controlled_vocabularies_path
        # The form route, not request.path: these trails are drawn on a POST, where
        # request.path is the index.
        add_breadcrumb t('hyku.admin.controlled_vocabulary.new_title'), main_app.new_controlled_vocabulary_path
      end

      # No :name — it is derived from the label on create, and a metadata profile
      # cites it, so staff do not get to set or change it.
      def controlled_vocabulary_params
        params.require(:local_authority).permit(:label, :description)
      end

      def prefill_params
        return {} if params[:local_authority].blank?

        controlled_vocabulary_params
      end
    end
  end
end
