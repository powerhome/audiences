# frozen_string_literal: true

RSpec.shared_examples "authenticated endpoint" do
  routes { Audiences::Engine.routes }

  it "requires authentication" do
    config_before = Audiences.config.authenticate
    Audiences.config.authenticate = ->(*) { false }

    expect(subject).to have_http_status(:unauthorized)
  ensure
    Audiences.config.authenticate = config_before
  end
end
