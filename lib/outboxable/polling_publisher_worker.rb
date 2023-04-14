module Outboxable
  class PollingPublisherWorker
    include Sidekiq::Job

    def perform
      Outboxable.configuration.orm == :mongoid ? perform_mongoid : perform_activerecord
    end

    def perform_activerecord
      Outbox.pending.where(last_attempted_at: [..Time.zone.now, nil]).find_in_batches(batch_size: 100).each do |batch|
        batch.each do |outbox|
          # This is to prevent a job from being retried too many times. Worst-case scenario is 1 minute delay in jobs.
          ::Outboxable::Worker.perform_async(outbox.id)
          outbox.update(last_attempted_at: 1.minute.from_now, status: :processing, allow_publish: false)
        end
      end
    end

    def perform_mongoid
      Outbox.pending.any_of({ last_attempted_at: ..Time.zone.now }, { last_attempted_at: nil }).each do |outbox|
        # This is to prevent a job from being retried too many times. Worst-case scenario is 1 minute delay in jobs.
        ::Outboxable::Worker.perform_async(outbox.idempotency_key)
        outbox.update(last_attempted_at: 1.minute.from_now, status: :processing, allow_publish: false)
      end
    end
  end
end
