# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Use command below to check grape routes
  # $ bin/rails grape:routes
  mount ApplicationAPI => "/api"

  resources :terms, only: %i[index show], constraints: { id: /.*/ }

  resources :dictionaries, only: [] do
    get "terms/:id" => "dictionary_terms#show", as: :term, constraints: { id: /.*/ }
  end

  get "bookmarks" => "pages#bookmarks", as: :bookmarks
  get "about" => "pages#about", as: :about
  get "statistics" => "pages#statistics", as: :statistics
  get "how-to-use" => "pages#how-to-use", as: :how_to_use
  get "info" => "pages#info", as: :info
  get "amis-writing-system" => "pages#amis-writing-system", as: :amis_writing_system
  get "amis-writing-system-pdf" => "pages#amis-writing-system-pdf", as: :amis_writing_system_pdf
  get "pourrias-poinsot-amis-han-intro" => "pages#pourrias-poinsot-amis-han-intro", as: :pourrias_poinsot_amis_han_intro
  get "namoh-intro" => "pages#namoh-intro", as: :namoh_intro
  get "namoh-recommendation" => "pages#namoh-recommendation", as: :namoh_recommendation
  get "namoh-how-to-use" => "pages#namoh-how-to-use", as: :namoh_how_to_use
  get "safolu-ch1-1" => "pages#safolu-ch1-1", as: :safolu_ch1_1
  get "safolu-ch1-2" => "pages#safolu-ch1-2", as: :safolu_ch1_2
  get "safolu-ch2-1" => "pages#safolu-ch2-1", as: :safolu_ch2_1

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "terms#index"
end
