# 🚨 Discontinuation Notice for ActiveRecord 🚨

**Effective Date: August 4, 2024**

Please be aware that we are no longer maintaing the part related to **ActiveRecord** in this gem. We are dropping support for ActiveRecord in favor of [Solid Queue](https://github.com/rails/solid_queue). 

In the meantime, we commit to continously support the Mongoid part of the gem.

### New Recommended Gem: `Solid Queue`

For ActiveRecord users, we recommend transitioning to the `Solid Queue` gem, which provides enhanced functionality, improved performance, and better support for modern application requirements. `Solid Queue` is designed to seamlessly integrate with your existing infrastructure while offering robust features to handle your queuing needs efficiently.


# Outboxable

The Outboxable Gem is tailored for Rails applications to implement the transactional outbox pattern. It supports both ActiveRecord and Mongoid.

Please take into consideration that this Gem is **opinionated**, meaning it expects you to follow a certain pattern and specific setting. If you don't like it, you can always fork it and change it.

### Restrictions

1. When using RabbitMQ, it only publishes events to a ***topic*** exchange.
1. It assumes that you are using routing keys to publish to the topic exchange.
1. It publishes events in a background job using [Sidekiq](https://github.com/sidekiq/sidekiq). Therefore, you application must use Sidekiq.
1. It implements the [polling publisher pattern](https://microservices.io/patterns/data/polling-publisher.html). For that, it uses [sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron) to check the unpublished outboxes every 5 seconds after the initialization of the application.

## Installation

Install the gem and add to the application's Gemfile by executing:

```ruby
$ bundle add outboxable
```

If bundler is not being used to manage dependencies, install the gem by executing:

```ruby
$ gem install outboxable
```

For use with ActiveRecord, run:

```shell
$ rails g outboxable:install --orm activerecord
```

For use with Mongoid, run:

```shell
$ rails g outboxable:install --orm mongoid
```

The command above will add a migration file and the Outbox model. You will need then to run the migrations (ActiveRecord only):

```shell
$ rails db:migrate
```

## Usage

The installation command above will also add a configuration file to your initializer:

```ruby
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
  # Specify the ORM you are using. Supported values are :activerecord and :mongoid
  config.orm = :activerecord

  # Specify the message broker you are using. For now, only RabbitMQ is supported.
  config.message_broker = :rabbitmq

  # RabbitMQ configurations
  config.rabbitmq_host = ENV.fetch('RABBITMQ__HOST')
  config.rabbitmq_port = ENV.fetch('RABBITMQ__PORT', 5672)
  config.rabbitmq_user = ENV.fetch('RABBITMQ__USERNAME')
  config.rabbitmq_password = ENV.fetch('RABBITMQ__PASSWORD')
  config.rabbitmq_vhost = ENV.fetch('RABBITMQ__VHOST')
  config.rabbitmq_exchange_name = ENV.fetch('RABBITMQ__EXCHANGE_NAME')
end
```

The monkey patch in the code above is crucial in giving you a way to customize the format of the message that you will publish to the message broker. Be default, it follows the specs of the [Cloud Native Events Specifications v1.0.2](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md).



### General use-cases

The Outboxable Gem provides a general-purpose polymorphic model for creating outboxes. In order to maintain a transactional outbox, the changes that occur to a resource and the associated outbox must happen within the same transaction:

```ruby
ActiveRecord::Base.transaction do
  book = Book.find(1)
  book.update!(title: 'Patterns of Enterprise Application Architecture', author: 'Martin Fowler')
  Outbox.create!(
    routing_key: 'books.updated',
    exchange: 'YOUR RABBITMQ EXCHANGE',
    payload: book.as_json,
    outboxable: book
  )
end

```


If you are intending to create an outbox that is not necessarily associated with a resource, you can use the following configuration that sets the ``size`` attribute to ``:batch``:

```ruby
ActiveRecord::Base.transaction do
  book = Book.find(1)
  book.update!(status: :published)
  Outbox.create!(
    routing_key: 'notifications.publish',
    exchange: 'YOUR EXCHANGE',
    payload: {
      channels: ['sms', 'email'],
      message: "Hello, world!"
    },
    size: :batch
  )
end
```



### The Outboxable Concern

The Outboxable Gem provides an ActiveRecord Model Concern that you can reuse in your models, which in turn will take care of transactionally creating events in case of create or update of the resource. All you have to do is to ``include Outboxable`` in your model and implement a method by the name of ``outbox_configurations``:



```ruby
class Book < ApplicationRecord
  include Outboxable

  # Enums
  enum status: { draft: 0, published: 1 }

  def outbox_configurations
    @outbox_configurations ||= {
      base: {
        routing_key: 'books'
      },
      run_on: {
        create: {},
        update: {
          condition: proc { |book| book.published? },
          routing_key: 'books.published'
        }
      }
    }
  end
end
```



The ``outbox_configurations`` method will be called and used by the Outboxable Gem to transactionally create an outbox and publish. In the code above, it will create an outbox when the book is created. For that purpose it will use the routing key ``books.created`` as a convention. It will also publish an event if the book is updated, using the routing key: ``books.published`` since it was specified in the hash.



Here's the schema of what could be passed to the ``outbox_configurations`` in JSON Schema format:

```json
{
  "type": "object",
  "properties": {
    "base": {
      "type": "object",
      "properties": {
        "routing_key": { "type": "string" }
      }
    },
    "run_on": {
      "type": "object",
      "properties": {
        "create": {
          "type": "object",
          "properties": {
            "condition": { "type": "Ruby Proc" },
            "routing_key": { "type": "string" }
          }
        },
        "update": {
          "type": "object",
          "properties": {
            "condition": { "type": "Ruby Proc" },
            "routing_key": { "type": "string" }
          }
        }
      }
    }
  }
}
```



The ``run_on`` key represents another hash that can have the keys ``create`` and ``update``. If one of these keys are not supplied, the outbox will not be created for the unspecified operation; in other words, if you do not specify the configuration for ``update``, for example, an outbox will NOT be created when the book is updated.

Each operation key such as ``create`` and ``update`` can also take a ``condition`` key, which represents a Ruby proc that must return a boolean expression. It can also take a ``routing_key`` option, which specifies that routing key with which the outbox will publish the event to the message broker. If you don't specify the ``routing_key``, it will use the base`s routing key dotted by``created`` for create operation and ``updated`` for update operation.



Last but not least, run sidekiq so that the Outboxable Gem can publish the events to the broker:

```shell
$ bundle exec sidekiq
```



### Mongoid

The Outboxable gem works smoothly with Mongoid. It is to be noted that when used with Mongoid, Outboxable does not use the `_id` as the idempotency key. It creates a field called ``idempotency_key`` which is a UUID generated at the time of the insertion of the document.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/outboxable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/outboxable/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Outboxable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/outboxable/blob/master/CODE_OF_CONDUCT.md).
