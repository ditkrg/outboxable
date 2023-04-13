# frozen_string_literal: true

require_relative 'outboxable/version'

require 'outboxable/worker'
require 'outboxable/publishing_manager'
require 'outboxable/polling_publisher_worker'
require 'outboxable/connection'
require 'outboxable/configuration'
require 'outboxable/rabbitmq/publisher'

require 'active_support/concern'

module Outboxable
  class Error < StandardError; end

  extend ActiveSupport::Concern

  included do
    after_create :instantiate_outbox_for_create, if: proc { |object| object.check_outbox_condition(object:, operation: :create) }
    after_update :instantiate_outbox_for_update, if: proc { |object| object.check_outbox_condition(object:, operation: :update) }

    has_many :outboxes, as: :outboxable, dependent: :destroy

    def instantiate_outbox(routing_key:)
      outboxes.new(
        routing_key:,
        exchange: Outboxable.configuration.rabbitmq_event_bus_exchange,
        payload: as_json
      )
    end

    def instantiate_outbox_for_create
      routing_key = outbox_configurations[:run_on][:create]&.[](:routing_key) || "#{outbox_configurations[:base][:routing_key]}.created"
      instantiate_outbox(routing_key:).save!
    end

    def instantiate_outbox_for_update
      routing_key = outbox_configurations[:run_on][:update]&.[](:routing_key) || "#{outbox_configurations[:base][:routing_key]}.updated"
      instantiate_outbox(routing_key:).save!
    end

    def check_outbox_condition(object:, operation:)
      # Check if called on create
      operation_is_included = object.outbox_configurations[:run_on].keys.include?(operation)

      # Check if there is a supplied condition
      supplied_condition_as_proc = object.outbox_configurations[:run_on][operation][:condition]

      # Return the result of operation is included if supplied condition is blank, which mean that there is no condition to be met
      return operation_is_included if supplied_condition_as_proc.blank?

      # Else check the condition as well as the inclusion of the operation
      operation_is_included && supplied_condition_as_proc.call(self)
    end
  end
end
