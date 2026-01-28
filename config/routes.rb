Rails.application.routes.draw do
  devise_for :users, controllers: {
    passwords: "users/passwords",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  devise_scope :user do
    get "users/show", to: "users/registrations#show", as: "user_profile"
  end

  # Defines the root path route ("/")
  # root "statics#home"

  root "products#index"
  resources :products, only: [:index, :show]

  resources :cart_items, path: "cart/items", only: [:index, :create, :update, :destroy]

  resources :orders, only: [:index, :new, :create, :show]

  # this routes not get executed if there is \d{3}.html file in /public
  match "/:status", to: "errors#show", constraints: {status: /\d{3}/}, via: :all

  namespace :admin do
    # root "statics#home"
    root "orders#index"

    resources :products
    resources :orders, only: [:index, :update, :show]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", :as => :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", :as => :pwa_manifest
end
