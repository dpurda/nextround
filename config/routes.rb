Rails.application.routes.draw do
  devise_for :users

  root "dashboard#show"

  resources :invites, only: %i[index new create show]
  resource :claim, only: %i[new create]
  resource :candidate_profile, only: %i[show new create edit update]
  resource :interviewer_profile, only: %i[show new create edit update]
  resources :interviews, only: %i[index show new create edit update] do
    member do
      patch :update_status
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
