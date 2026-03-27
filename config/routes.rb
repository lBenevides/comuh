Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "communities#index"

  resources :communities, only: [:index, :show]
  resources :messages, only: [:show, :create]
  resources :reactions, only: [:create]

  namespace :api do
    namespace :v1 do
      resources :messages, only: [:create]
      resources :reactions, only: [:create]
      get "communities/:id/messages/top", to: "communities#top"
      get "analytics/suspicious_ips", to: "analytics#suspicious_ips"
    end
  end
end
