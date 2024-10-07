# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Use command below to check grape routes
  # $ bin/rails grape:routes
  mount ApplicationAPI => "/api"

  resources :terms, only: %i[index show]

  resources :dictionaries, only: [] do
    get "terms/:id" => "dictionary_terms#show", as: :term
  end

  get "bookmarks" => "pages#bookmarks", as: :bookmarks
  get "about"     => "pages#about",     as: :about

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "terms#index"
end
