# frozen_string_literal: true

# OVERRIDE Hyrax 2.9.0 to add featured collection routes

require 'sidekiq/web' if ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', 'sidekiq') == 'sidekiq'

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  resources :identity_providers
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  concern :iiif_search, BlacklightIiifSearch::Routes.new
  concern :oai_provider, BlacklightOaiProvider::Routes.new
  mount WillowSword::Engine => '/sword'

  mount Hyrax::IiifAv::Engine, at: '/'
  mount IiifPrint::Engine, at: '/'
  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?

  authenticate :user, ->(u) { u.superadmin? || u.admin? } do
    queue = ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', 'sidekiq')
    case queue
    when 'sidekiq'
      mount Sidekiq::Web => '/jobs'
    when 'good_job'
      mount GoodJob::Engine => '/jobs'
    end
  end

  if ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MULTITENANT', false))
    constraints host: Account.admin_host do
      get '/account/sign_up' => 'account_sign_up#new', as: 'new_sign_up'
      post '/account/sign_up' => 'account_sign_up#create'
      get '/', to: 'splash#index', as: 'splash'

      # pending https://github.com/projecthydra-labs/hyrax/issues/376
      get '/dashboard', to: redirect('/')

      namespace :proprietor do
        resources :accounts
        resources :users do
          member do
            post :become
          end
        end
      end
    end
  end

  get 'status', to: 'status#index'

  # routes for the  api
  namespace :api, defaults: { format: :json } do
    resource :sushi do
      collection do
        get 'r51/status', to: 'sushi#server_status'
        get 'r51/reports', to: 'sushi#report_list'
        get 'r51/reports/pr', to: 'sushi#platform_report'
        get 'r51/reports/pr_p1', to: 'sushi#platform_usage'
        get 'r51/reports/ir', to: 'sushi#item_report'
      end
    end
  end

  mount BrowseEverything::Engine => '/browse'

  resource :site, only: [:update] do
    resource :labels, only: %i[edit update]
    resources :roles, only: %i[index update]
  end

  root 'hyrax/homepage#index'

  devise_for :users, skip: [:omniauth_callbacks], controllers: { invitations: 'hyku/invitations',
                                                                 registrations: 'hyku/registrations',
                                                                 omniauth_callbacks: 'users/omniauth_callbacks' }
  as :user do
    resources :single_signon, only: [:index]

    Devise.omniauth_providers.each do |provider|
      path_prefix = '/users/auth'
      match "#{path_prefix}/#{provider}/:id",
        to: "users/omniauth_callbacks#passthru",
        as: "user_#{provider}_omniauth_authorize",
        via: OmniAuth.config.allowed_request_methods

      get "#{path_prefix}/#{provider}/:id/metadata", to: "users/omniauth_callbacks#passthru", as: "user_#{provider}_omniauth_metadata"

      match "#{path_prefix}/#{provider}/:id/callback",
        to: "users/omniauth_callbacks##{provider}",
        as: "user_#{provider}_omniauth_callback",
        via: [:get, :post]
    end
  end

  mount Qa::Engine => '/authorities'

  mount Blacklight::Engine => '/'
  mount BlacklightAdvancedSearch::Engine => '/'
  mount Hyrax::Engine, at: '/'
  mount Bulkrax::Engine, at: '/' if Hyku.bulkrax_enabled?
  mount HykuKnapsack::Engine, at: '/'
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  curation_concerns_basic_routes

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :oai_provider

    concerns :searchable
    concerns :range_searchable
  end

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
    concerns :iiif_search
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  namespace :admin do
    resource :account, only: %i[edit update]
    resource :work_types, only: %i[edit update]
    resources :users, only: [:index, :destroy] do
      post 'activate', on: :member
      delete 'remove_role/:role_id', on: :member, to: 'users#remove_role', as: :remove_role
    end
    resources :groups do
      member do
        get :remove
      end

      resources :users, only: %i[index create destroy], param: :user_id, controller: 'group_users'
      resources :roles, only: %i[index create destroy], param: :role_id, controller: 'group_roles'
    end
    post "roles_service/:job_name_key", to: "roles_service#update_roles", as: :update_roles
    get "roles_service", to: "roles_service#index", as: :roles_service_jobs
  end

  # OVERRIDE here to add featured collection routes
  scope module: 'hyrax' do
    # Generic collection routes
    resources :collections, only: [] do
      member do
        resource :featured_collection, only: %i[create destroy]
      end
    end
    resources :featured_collection_lists, path: 'featured_collections', only: :create
  end

  get 'all_collections' => 'hyrax/homepage#all_collections', as: :all_collections

  # Upload a collection thumbnail
  post "/dashboard/collections/:id/delete_uploaded_thumbnail",
       to: "hyrax/dashboard/collections#delete_uploaded_thumbnail",
       as: :delete_uploaded_thumbnail

  if ENV.fetch('HYRAX_FLEXIBLE', false)
    # Metadata profiles routes
    resources :metadata_profiles, except: [:update, :show, :destroy] do
      collection { post :import }
      get 'export'
    end
  end
end
