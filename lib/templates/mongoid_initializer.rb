# This monkey patch allows you to customize the message format that you publish to your broker.
# By default, Outboxable publishes a CloudEvent message to your broker.
module Outboxable
  module RabbitMq
    class Publisher
      # Override this method to customize the message format that you publish to your broker
      # DO NOT CHANGE THE METHOD SIGNATURE
      def to_envelope(resource:)
        {
          id: resource.id,
          source: 'http://localhost:3000',
          specversion: '1.0',
          type: resource.routing_key,
          datacontenttype: 'application/json',
          data: resource.payload
        }.to_json
      end
    end
  end
end

Outboxable.configure do |config|
  # Specify the ORM you are using. For now, only ActiveRecord is supported.
  config.orm = :mongoid

  # Specify the message broker you are using. For now, only RabbitMQ is supported.
  config.message_broker = :rabbitmq

  # RabbitMQ configurations
  config.rabbitmq_host = ENV.fetch('RABBITMQ__HOST')
  config.rabbitmq_port = ENV.fetch('RABBITMQ__PORT', 5672)
  config.rabbitmq_user = ENV.fetch('RABBITMQ__USERNAME')
  config.rabbitmq_password = ENV.fetch('RABBITMQ__PASSWORD')
  config.rabbitmq_vhost = ENV.fetch('RABBITMQ__VHOST')
  config.rabbitmq_event_bus_exchange = ENV.fetch('EVENTBUS__EXCHANGE_NAME')
end
