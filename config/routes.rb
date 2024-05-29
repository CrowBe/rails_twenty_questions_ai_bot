Rails.application.routes.draw do
  # refresh chat history
  root 'user_sessions#new'
  
  resources :user_sessions, only: [:new, :create]
  delete '/destroy_messages', controller:'messages', action:'destroy_all'
  resources :messages, only: [:index, :create]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
