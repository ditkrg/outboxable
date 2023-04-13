module Outboxable
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)

    # In accordance to sidekiq-cron README: https://github.com/sidekiq-cron/sidekiq-cron#under-the-hood
    Sidekiq::Options[:cron_poll_interval] = 5

    # Create the cron job for the polling publisher
    Sidekiq::Cron::Job.create(name: 'OutboxablePollingPublisher', cron: '*/5 * * * * *', class: 'Outboxable::PollingPublisherWorker', args: [{ orm: configuration.orm }])
  end

  class Configuration
    ALLOWED_MESSAGE_BROKERS = %i[rabbitmq].freeze
    ALLOWED_ORMS = %i[activerecord mongoid].freeze

    attr_accessor :rabbitmq_host,
                  :rabbitmq_port,
                  :rabbitmq_user,
                  :rabbitmq_password,
                  :rabbitmq_vhost,
                  :rabbitmq_event_bus_exchange,
                  :message_broker,
                  :orm

    def initialize
      raise Error, 'Sidekiq is not available. Unfortunately, sidekiq must be available for Outboxable to work' unless Object.const_defined?('Sidekiq')
      raise Error, 'Outboxable Gem only supports Rails but you application does not seem to be a Rails app' unless Object.const_defined?('Rails')
      raise Error, 'Outboxable Gem only support Rails version 7 and newer' if Rails::VERSION::MAJOR < 7
      raise Error, 'Outboxable Gem uses the sidekiq-cron Gem. Make sure you add it to your project' unless Object.const_defined?('Sidekiq::Cron')
    end

    def message_broker=(message_broker)
      raise ArgumentError, "Message broker must be one of #{ALLOWED_MESSAGE_BROKERS}" unless ALLOWED_MESSAGE_BROKERS.include?(message_broker)

      @message_broker = message_broker
    end

    def message_broker
      @message_broker || :rabbitmq
    end

    def orm=(orm)
      raise ArgumentError, "ORM must be one of #{ALLOWED_ORMS}" unless ALLOWED_ORMS.include?(orm)

      @orm = orm
    end

    def orm
      @orm || :activerecord
    end
  end
end
