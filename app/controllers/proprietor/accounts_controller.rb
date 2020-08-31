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
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.admin.sidebar.accounts'), proprietor_accounts_path
      add_breadcrumb @account.tenant, edit_proprietor_account_path(@account)
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
      respond_to do |format|
        if @account.update(account_params)
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
      def account_params
        params.require(:account).permit(:name, :cname, :title,
                                        admin_emails: [],
                                        solr_endpoint_attributes: %i[id url],
                                        fcrepo_endpoint_attributes: %i[id url base_path])
      end
  end
end
