module Outboxable
  class PublishingManager
    def self.publish(resource:)
      case Outboxable.configuration.message_broker
      when :rabbitmq
        Outboxable::RabbitMq::Publisher.new(resource:).publish
      end
    end
  end
end
