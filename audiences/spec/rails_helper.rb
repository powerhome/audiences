# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "spec_helper"

require File.expand_path "dummy/config/environment", __dir__

require "rspec/rails"
require "shoulda/matchers"
require "webmock/rspec"

require_relative "support/factories"

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.include Rails.application.routes.url_helpers, type: :request
  config.include Audiences::Test::Factories

  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  config.before do
    Audiences::Notifications.subscriptions.clear
  end
end
