class Outbox < ApplicationRecord
  attribute :allow_publish, :boolean, default: true

  before_save :check_publishing
  # Callbacks
  before_create :set_last_attempted_at
  after_commit :publish, if: :allow_publish?
  # Enums
  enum status: { pending: 0, processing: 1, published: 2, failed: 3 }
  enum size: { single: 0, batch: 1 }

  # Validations
  validates :payload, :exchange, :routing_key, presence: true

  # Associations
  belongs_to :outboxable, polymorphic: true, optional: true

  def set_last_attempted_at
    self.last_attempted_at = 10.seconds.from_now
  end

  def publish
    # Run this in own thread
    threaded = Thread.new do
      Outboxable::Worker.perform_inline(id)
      update(status: :processing, last_attempted_at: 1.minute.from_now, allow_publish: false)
    end
    threaded.join
  end

  def check_publishing
    self.allow_publish = false if published?
  end
end
