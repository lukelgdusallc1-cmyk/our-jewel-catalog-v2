Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "catalog#index"

  resources :catalog, only: [:show]

  resources :supplier_fetches, only: [:index, :create]

  resource :settings, only: [:edit, :update]

  resources :histories, only: [:index]

  get "push_preview", to: "push_previews#show",
      as: :push_preview

  # Shopify authentication will be enabled after configuration.
  mount ShopifyApp::Engine, at: "/"
end