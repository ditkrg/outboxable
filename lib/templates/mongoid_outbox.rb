class Outbox
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_writer :allow_publish

  # Fields
  field :status, type: String, default: 'pending'
  field :size,   type: String, default: 'single'

  field :exchange, type: String, default: ''
  field :routing_key, type: String, default: ''
  field :content_type, type: String, default: 'application/json'

  field :attempts, type: Integer, default: 0

  field :last_attempted_at, type: DateTime, default: nil

  field :retry_at, type: DateTime, default: nil

  field :idempotency_key, type: String

  field :payload, type: Hash, default: {}
  field :headers, type: Hash, default: {}
  field :metadata, type: Hash, default: {}

  index({ idempotency_key: 1 }, { unique: true, name: 'idempotency_key_unique_index' })

  before_save :check_publishing
  before_create :set_idempotency_key

  # Callbacks
  before_create :set_last_attempted_at
  after_save :publish, if: :allow_publish

  # Validations
  validates :payload, :exchange, :routing_key, presence: true

  # Associations
  belongs_to :outboxable, polymorphic: true, optional: true

  def set_last_attempted_at
    self.last_attempted_at = 10.seconds.from_now
  end

  def publish
    Outboxable::Worker.perform_async(idempotency_key)
    update(status: :processing, last_attempted_at: 1.minute.from_now, allow_publish: false)
  end

  def set_idempotency_key
    self.idempotency_key = SecureRandom.uuid if idempotency_key.blank?
  end

  def check_publishing
    self.allow_publish = false if published?
  end

  def allow_publish
    return true if @allow_publish.nil?

    @allow_publish
  end

  %w[pending processing published failed].each do |status|
    define_method "#{status}?" do
      self.status == status
    end

    # define scope
    scope status, -> { where(status:) }
  end
end
