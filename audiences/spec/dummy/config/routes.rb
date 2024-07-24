# frozen_string_literal: true

Rails.application.routes.draw do
  resources :example_owners
  mount Audiences::Engine, at: "/audiences"
  root to: "example_owners#index"
end
