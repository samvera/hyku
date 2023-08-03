# frozen_string_literal: true

# OVERRIDE Hyrax 2.9.0 to add featured collection routes

require 'sidekiq/web'

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  resources :auth_providers
  concern :iiif_search, BlacklightIiifSearch::Routes.new
  concern :oai_provider, BlacklightOaiProvider::Routes.new

  mount Hyrax::IiifAv::Engine, at: '/'
  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?

  authenticate :user, ->(u) { u.is_superadmin } do
    mount Sidekiq::Web => '/sidekiq'
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
        resources :users
      end
    end
  end

  get 'status', to: 'status#index'

  mount BrowseEverything::Engine => '/browse'
  resource :site, only: [:update] do
    resources :roles, only: %i[index update]
    resource :labels, only: %i[edit update]
  end

  root 'hyrax/homepage#index'

  devise_for :users, controllers: { invitations: 'hyku/invitations',
                                    registrations: 'hyku/registrations',
                                    omniauth_callbacks: 'users/omniauth_callbacks' }

  mount Qa::Engine => '/authorities'

  mount Blacklight::Engine => '/'
  mount Hyrax::Engine, at: '/'
  mount Bulkrax::Engine, at: '/' if ENV.fetch('HYKU_BULKRAX_ENABLED', 'true') == 'true'

  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  curation_concerns_basic_routes

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :oai_provider

    concerns :searchable
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
    resources :users, only: [:destroy]
    resources :groups do
      member do
        get :remove
      end

      resources :users, only: %i[index create destroy], param: :user_id, controller: 'group_users'
      resources :roles, only: %i[index create destroy], param: :role_id, controller: 'group_roles'
    end
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
end
