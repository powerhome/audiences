# frozen_string_literal: true

Audiences::Engine.routes.draw do
  root "contexts#show"

  get "/scim(/*scim_path)" => "scim_proxy#get", as: :scim_proxy
  get "/:key" => "contexts#show", as: :signed_context
  get "/:key/users(/:criterion_id)" => "contexts#users", as: :users
  put "/:key" => "contexts#update"
end
