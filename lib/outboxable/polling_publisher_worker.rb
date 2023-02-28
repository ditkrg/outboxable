module Outboxable
  class PollingPublisherWorker
    include Sidekiq::Job
    sidekiq_options queue: 'critical'

    def perform
      Outbox.pending.find_in_batches(batch_size: 100).each do |batch|
        batch.each do |outbox|
          Outboxable::Worker.perform_async(outbox.id)
        end
      end
    end
  end
end