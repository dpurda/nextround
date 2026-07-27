Rails.application.routes.draw do
  devise_for :users

  root "dashboard#show"

  resources :invites, only: %i[index new create show]
  resource :claim, only: %i[new create]
  resource :candidate_profile, only: %i[show new create edit update]
  resource :interviewer_profile, only: %i[show new create edit update]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
