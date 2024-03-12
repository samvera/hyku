# frozen_string_literal: true

module Proprietor
  class AccountsController < ProprietorController
    before_action :ensure_admin!

    load_and_authorize_resource

    # GET /accounts
    # GET /accounts.json
    def index
      authorize! :manage, Account
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.accounts'), proprietor_accounts_path
    end

    # GET /accounts/1
    # GET /accounts/1.json
    def show
      @users = User.accessible_by(current_ability)

      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.accounts'), proprietor_accounts_path
      add_breadcrumb @account.tenant, edit_proprietor_account_path(@account)

      admin_page = params[:user_superadmin_page]
      @current_superusers = User.where(email: @account.admin_emails).page(admin_page).per(5) if @account.admin_emails
      @current_nonadmin_users = User.order('email').page(params[:user_page]).per(5)
    end

    # GET /accounts/new
    def new
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.accounts'), proprietor_accounts_path
      add_breadcrumb 'New account', new_proprietor_account_path
    end

    # GET /accounts/1/edit
    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.accounts'), proprietor_accounts_path
      add_breadcrumb @account.tenant, edit_proprietor_account_path(@account)
    end

    # POST /accounts
    # POST /accounts.json
    def create
      respond_to do |format|
        create_account = CreateAccount.new(@account, super_and_current_users)
        if create_account.save
          format.html { redirect_to [:proprietor, @account], notice: 'Account was successfully created.' }
          format.json { render :show, status: :created, location: @account.cname }
        else
          format.html { render :new }
          format.json { render json: @account.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /accounts/1
    # PATCH/PUT /accounts/1.json
    def update
      @account.data_cite_endpoint = DataCiteEndpoint.new unless @account.data_cite_endpoint.persisted?

      respond_to do |format|
        if @account.update(edit_account_params)
          f = edit_account_params['full_account_cross_searches_attributes'].to_h
          CreateSolrCollectionJob.perform_now(@account) if deleted_or_new(f)

          format.html { redirect_to [:proprietor, @account], notice: 'Account was successfully updated.' }
          format.json { render :show, status: :ok, location: [:proprietor, @account] }
        else
          format.html { render :edit }
          format.json { render json: @account.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /accounts/1
    # DELETE /accounts/1.json
    def destroy
      CleanupAccountJob.perform_now(@account)

      respond_to do |format|
        format.html { redirect_to proprietor_accounts_url, notice: 'Account was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def ensure_admin!
      authorize! :read, :admin_dashboard
    end

    # Never trust parameters from the scary internet, only allow the permitted parameters through.
    def edit_account_params
      params.require(:account).permit(
        :name,
        :cname,
        :title,
        :is_public,
        :search_only,
        *@account.live_settings.keys,
        admin_emails: [],
        full_account_cross_searches_attributes: [:id, :_destroy, :full_account_id, full_account_attributes: [:id]],
        solr_endpoint_attributes: %i[id url],
        fcrepo_endpoint_attributes: %i[id url base_path],
        data_cite_endpoint_attributes: %i[mode prefix username password],
        domain_names_attributes: %i[id tenant cname is_active _destroy]
      )
    end

    def account_params
      params.require(:account).permit(
        :name,
        :search_only,
        admin_emails: [],
        full_account_cross_searches_attributes: [:id, :_destroy, :full_account_id, full_account_attributes: [:id]]
      )
    end

    def deleted_or_new(hash)
      hash.detect do |_k, v|
        ActiveModel::Type::Boolean.new.cast(v["_destroy"]) == true || v["id"].blank?
      end
    end
  end
end
