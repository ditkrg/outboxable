module Outboxable
  module RabbitMq
    class Publisher
      def initialize(resource:)
        @resource = resource
      end

      def to_envelope(resource:)
        # throw not implemented method error
        raise NotImplementedError, 'Please implement the to_envelope method in your own module'
      end

      def publish
        confirmed = nil

        Outboxable::Connection.instance.channel.with do |channel|
          channel.confirm_select

          # Declare a exchange
          exchange = channel.topic(@resource.exchange, durable: true)

          # Publish the CloudEvent resource to the exchange
          exchange.publish(to_envelope(resource: @resource), routing_key: @resource.routing_key, headers: @resource.try(:headers) || {})

          # Wait for confirmation
          confirmed = channel.wait_for_confirms
        end

        return unless confirmed

        @resource.reload
        @resource.increment_attempt
        @resource.update(status: :published, retry_at: nil)
      end
    end
  end
end
