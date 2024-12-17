# frozen_string_literal: true

Audiences::Engine.routes.draw do
  root "contexts#show"

  get "/scim(/*scim_path)" => "scim_proxy#get", as: :scim_proxy
  get "/:key" => "contexts#show", as: :signed_context
  get "/:key/users(/:criterion_id)" => "contexts#users", as: :users
  put "/:key" => "contexts#update"
end

Rails.application.routes.draw do
  direct :audience_context do |owner, relation = nil|
    context = Audiences::Context.for(owner, relation: relation)
    audiences.route_for(:signed_context, key: context.signed_key, **url_options)
  end

  direct :audience_scim_proxy do |options|
    audiences.route_for(:scim_proxy, **url_options, **options)
  end
end
