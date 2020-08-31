# frozen_string_literal: true

module Proprietor
  class UsersController < ProprietorController
    before_action :ensure_admin!

    before_action :find_user, only: %i[show edit update destroy]
    load_and_authorize_resource

    # GET /users
    # GET /users.json
    def index
      authorize! :manage, User
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.users'), proprietor_users_path
    end

    # GET /users/1
    # GET /users/1.json
    def show
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.users'), proprietor_users_path
      add_breadcrumb @user.display_name, edit_proprietor_user_path(@user)
    end

    # GET /users/new
    def new
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.users'), proprietor_users_path
      add_breadcrumb 'New user', new_proprietor_user_path
    end

    # GET /users/1/edit
    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.users'), proprietor_users_path
      add_breadcrumb @user.display_name, edit_proprietor_user_path(@user)
    end

    # POST /users
    # POST /users.json
    def create
      @user = User.new(user_params)
      respond_to do |format|
        if @user.valid? && @user.save
          format.html { redirect_to proprietor_users_path, notice: 'User was successfully created.' }
          format.json { render :show, status: :created, location: [:proprietor, @user] }
        else
          format.html { render :new }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /users/1
    # PATCH/PUT /users/1.json
    def update
      respond_to do |format|
        if @user.update(user_params)
          format.html { redirect_to proprietor_users_path, notice: 'User was successfully updated.' }
          format.json { render :show, status: :ok, location: [:proprietor, @user] }
        else
          format.html { render :edit }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /users/1
    # DELETE /users/1.json
    def destroy
      message = if @user.destroy
                  'User was successfully destroyed.'
                else
                  'User could not be destroyed.'
                end

      respond_to do |format|
        format.html { redirect_to proprietor_users_url, notice: message }
        format.json { head :no_content }
      end
    end

    private

      def ensure_admin!
        authorize! :read, :admin_dashboard
      end

      def user_params
        # remove blank passwords
        params[:user].delete(:password) if params[:user] && params[:user][:password].blank?

        params.require(:user).permit(:email,
                                     :password,
                                     :is_superadmin,
                                     :facebook_handle,
                                     :twitter_handle,
                                     :googleplus_handle,
                                     :display_name,
                                     :address,
                                     :department,
                                     :title,
                                     :office,
                                     :chat_id,
                                     :website,
                                     :affiliation,
                                     :telephone,
                                     :avatar,
                                     :group_list,
                                     :linkedin_handle,
                                     :orcid,
                                     :arkivo_token,
                                     :arkivo_subscription,
                                     :zotero_token,
                                     :zotero_userid,
                                     :preferred_locale,
                                     role_ids: [])
      end

      def find_user
        @user ||= ::User.from_url_component(params[:id])
        raise ActiveRecord::RecordNotFound unless @user
      end
  end
end
