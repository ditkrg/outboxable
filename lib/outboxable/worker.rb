module Outboxable
  class Worker
    include Sidekiq::Job

    def perform(outbox_id)
      Outboxable::PublishingManager.publish(resource: Outbox.find(outbox_id))
    end
  end
end
