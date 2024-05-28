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

          content_type = if @resource.respond_to?(:content_type) && @resource.content_type.present?
                           @resource.content_type
                         else
                           'application/json'
                         end

          # Publish the CloudEvent resource to the exchange
          exchange.publish(
            to_envelope(resource: @resource),
            routing_key: @resource.routing_key,
            headers: @resource.try(:headers) || {},
            content_type:
          )

          # Wait for confirmation
          confirmed = channel.wait_for_confirms
        end

        return unless confirmed

        @resource.reload
        @resource.update(status: :published, retry_at: nil)
      end
    end
  end
end
