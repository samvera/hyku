Rails.application.routes.draw do
  resource :site, only: [:edit, :update] do
    resources :roles, only: [:index, :update]
  end

  resources :accounts
  root 'sufia/homepage#index'

  mount Blacklight::Engine => '/'
  mount Hydra::Collections::Engine => '/'
  mount CurationConcerns::Engine, at: '/'

  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  devise_for :users
  Hydra::BatchEdit.add_routes(self)

  curation_concerns_embargo_management

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # This must be the very last route in the file because it has a catch-all route for 404 errors.
  # This behavior seems to show up only in production mode.
  mount Sufia::Engine => '/'
end
