# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audiences::Notifications do
  it "allows subscribing by owner type" do
    owner = ExampleOwner.create
    context = Audiences::Context.new(owner: owner)

    expect do |blk|
      Audiences::Notifications.subscribe ExampleOwner, &blk
      Audiences::Notifications.publish context
    end.to yield_with_args context
  end

  context "subscribing a job" do
    it "allows subscribing a job to perform later" do
      owner = ExampleOwner.create
      context = Audiences::Context.create(owner: owner)
      Audiences::Notifications.subscribe ExampleOwner, job: UpdateMembershipsJob

      expect do
        Audiences::Notifications.publish context
      end.to have_enqueued_job(UpdateMembershipsJob).with(context).exactly(:once)
    end

    it "allows subscribing a job to perform later with options" do
      owner = ExampleOwner.create
      context = Audiences::Context.create(owner: owner)
      Audiences::Notifications.subscribe ExampleOwner, job: UpdateMembershipsJob.set(queue: "low")

      expect do
        Audiences::Notifications.publish context
      end.to have_enqueued_job(UpdateMembershipsJob).with(context)
                                                    .on_queue("low")
                                                    .exactly(:once)
    end
  end
end
