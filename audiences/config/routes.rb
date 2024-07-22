# frozen_string_literal: true

Audiences::Engine.routes.draw do
  get "/scim(/*scim_path)" => "scim_proxy#get", as: :scim_proxy
  get "/:key" => "contexts#show", as: :signed_context
  get "/:key/users(/:criterion_id)" => "contexts#users", as: :users
  put "/:key" => "contexts#update"
end

Rails.application.routes.draw do
  mount Audiences::Engine, at: "/audiences", as: :audiences

  direct :audience_context do |context, relation = nil|
    context = Audiences::Context.for(context, relation: relation)
    audiences.route_for(:signed_context, key: context.signed_key)
  end

  direct :audience_scim_proxy do |options|
    audiences.route_for(:scim_proxy, **options)
  end
end
