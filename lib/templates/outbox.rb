class Outbox < ApplicationRecord
  attribute :allow_publish, :boolean, default: true

  # Callbacks
  before_create :set_last_attempted_at
  before_save :check_publishing
  after_commit :publish, if: :allow_publish?
  # Enums
  enum status: { pending: 0, published: 1, failed: 2 }
  enum size: { single: 0, batch: 1 }

  # Validations
  validates :payload, presence: true
  validates :exchange, presence: true
  validates :routing_key, presence: true

  # Associations
  belongs_to :outboxable, polymorphic: true, optional: true

  def set_last_attempted_at
    self.last_attempted_at = Time.zone.now
  end

  def publish
    Outboxable::Worker.perform_async(id)
  end

  def check_publishing
    self.allow_publish = false if published?
  end
end
