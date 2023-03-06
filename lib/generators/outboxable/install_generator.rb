module Outboxable
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../../templates', __dir__)

    # Copy initializer into user app
    def copy_initializer
      copy_file('initializer.rb', 'config/initializers/z_outboxable.rb')
    end

    # Copy user information (model & Migrations) into user app
    def create_user_model
      target_path = 'app/models/outbox.rb'
      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Model outbox already exists')
      else
        template('outbox.rb', target_path)
      end
    end

    # Copy migrations
    def copy_migrations
      if self.class.migration_exists?('db/migrate', 'create_outboxable_outboxes')
        say_status('skipped', 'Migration create_outboxable_outboxes already exists')
      else
        migration_template('create_outboxable_outboxes.rb', 'db/migrate/create_outboxable_outboxes.rb')
      end
    end

    # Use to assign migration time otherwise generator will error
    def self.next_migration_number(_dir)
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end
  end
end
