# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::ContextExtraUser do
  describe "associations" do
    it { is_expected.to belong_to(:context) }
    it { is_expected.to belong_to(:external_user) }
  end

  it "holds a configured reference alongside the legacy one" do
    context = create_context(extra_users: [create_user])
    context_extra_user = context.context_extra_users.first

    context_extra_user.update!(configured_user: ExampleSourceUser.create!(display_name: "Jane Doe"))

    expect(context_extra_user.reload.configured_user).to be_an(ExampleSourceUser)
    expect(context_extra_user.external_user).to be_an(Audiences::ExternalUser)
  end
end
