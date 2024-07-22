# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Model do
  subject { ExampleOwner.new }

  describe "dynamic owner to audience relations" do
    it do
      is_expected.to have_one(:members_context).class_name("Audiences::Context")
    end
    it do
      is_expected.to have_many(:members_external_users).class_name("Audiences::ExternalUser")
                                                       .through(:members_context)
                                                       .source(:users)
    end
    it do
      is_expected.to have_many(:members).through(:members_external_users)
                                        .source(:identity)
    end
  end
end
