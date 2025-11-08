# frozen_string_literal: true

class Bookmark < ApplicationRecord
  include Discard::Model

  # Associations
  belongs_to :user
  belongs_to :collection, optional: true
  has_many :bookmark_tags, dependent: :destroy
  has_many :tags, -> { kept }, through: :bookmark_tags

  # Validations
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :saved_at, presence: true
  validates :status, inclusion: { in: %w[unsorted read archived favorite] }
  validates :source, inclusion: { in: %w[manual heyho import] }

  # Scopes
  scope :by_collection, ->(collection_id) { where(collection_id:) }
  scope :recent, -> { order(saved_at: :desc) }
  scope :favorites, -> { where(status: "favorite") }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :unread, -> { where(status: "unsorted") }
  scope :read, -> { where(status: "read") }
  scope :by_tag, ->(tag_id) { joins(:tags).where(tags: { id: tag_id }) }
  scope :by_status, ->(status) { where(status:) }
  scope :from_heyho, -> { where(source: "heyho") }

  # Callbacks
  before_validation :set_saved_at, on: :create, if: -> { saved_at.blank? }
  before_validation :extract_domain_from_url
  after_create :assign_to_default_collection, if: -> { collection_id.blank? }

  # Instance methods

  def extract_domain
    return nil if url.blank?

    uri = URI.parse(url)
    uri.host&.sub(/^www\./, "")
  rescue URI::InvalidURIError
    nil
  end

  def mark_as_read!
    update(status: "read", read_at: Time.current)
  end

  def archive!
    update(status: "archived", archived_at: Time.current)
  end

  def favorite!
    update(status: "favorite")
  end

  def unfavorite!
    update(status: "read")
  end

  private

  def set_saved_at
    self.saved_at = Time.current
  end

  def extract_domain_from_url
    return if url.blank?

    domain = extract_domain
    self.metadata ||= {}
    self.metadata["domain"] = domain if domain.present?
  end

  def assign_to_default_collection
    default_collection = user.collections.defaults.first
    update_column(:collection_id, default_collection.id) if default_collection
  end
end
