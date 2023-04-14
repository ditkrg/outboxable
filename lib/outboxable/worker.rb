require 'sidekiq'

module Outboxable
  class Worker
    include ::Sidekiq::Job

    def perform(outbox_id)
      Outboxable::PublishingManager.publish(resource: Outbox.find(outbox_id)) if Outboxable.configuration.orm == :activerecord
      Outboxable::PublishingManager.publish(resource: Outbox.find_by!(idempotency_key: outbox_id)) if Outboxable.configuration.orm == :mongoid
    end
  end
end
