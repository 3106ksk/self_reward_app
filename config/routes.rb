Rails.application.routes.draw do
  resources :posts
  root "maps#show"

  resources :users, only: %i[ new create ]

  get "login", to: "user_sessions#new"
  post "login", to: "user_sessions#create"
  delete "logout", to: "user_sessions#destroy"

  resource :map, only: :show

  resources :goals, only: :update do
    resources :subgoals, only: :create
  end

  resources :subgoals, only: %i[ create edit update destroy ] do
    patch :claim_reward, on: :member
    resources :todo_items, only: :create
  end

  resources :todo_items, only: %i[ create edit update ] do
    patch :toggle, on: :member
  end

  get "prototype" => "prototype#home"
  get "prototype/onboarding" => "prototype#onboarding"
  get "prototype/today" => "prototype#today"
  get "prototype/rest" => "prototype#rest"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
