class CreateOutboxableOutboxes < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :outboxes, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.integer :status, null: false, default: 0

      t.string :exchange, null: false, default: ''
      t.string :routing_key, null: false, default: ''

      t.integer  :attempts, null: false, default: 0
      t.datetime :last_attempted_at, null: true
      t.datetime :retry_at, null: true

      t.jsonb :payload, default: {}
      t.jsonb :headers, default: {}

      t.integer :size, null: false, default: 0

      t.references :outboxable, polymorphic: true, null: true

      t.timestamps
    end

    add_index :outboxes, %i[status last_attempted_at], name: 'index_outboxes_on_outboxable_status_and_last_attempted_at'
  end
end
