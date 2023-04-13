module Outboxable
  class PollingPublisherWorker
    include Sidekiq::Job
    sidekiq_options queue: 'critical'

    def perform
      Outbox.pending.where(last_attempted_at: [..Time.zone.now, nil]).find_in_batches(batch_size: 100).each do |batch|
        batch.each do |outbox|
          # This is to prevent a job from being retried too many times. Worst-case scenario is 1 minute delay in jobs.
          Outboxable::Worker.perform_async(outbox.id)
          outbox.update(last_attempted_at: 1.minute.from_now, status: :processing, allow_publish: false)
        end
      end
    end
  end
end
