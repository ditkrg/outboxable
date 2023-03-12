require 'singleton'

module Outboxable
  class Connection
    include ::Singleton
    attr_reader :connection

    def initialize
      @connection = Bunny.new(
        host: Outboxable.configuration.rabbitmq_host,
        port: Outboxable.configuration.rabbitmq_port,
        user: Outboxable.configuration.rabbitmq_user,
        password: Outboxable.configuration.rabbitmq_password,
        vhost: Outboxable.configuration.rabbitmq_vhost
      )

      @connection.start
    end

    def channel
      @channel ||= ConnectionPool.new do
        connection.create_channel
      end
    end
  end
end
