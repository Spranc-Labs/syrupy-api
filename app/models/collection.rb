# frozen_string_literal: true

class Collection < ApplicationRecord
  include Discard::Model

  # Associations
  belongs_to :user
  has_many :bookmarks, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id, conditions: -> { kept } }
  validates :color, format: { with: /\A#[0-9a-fA-F]{6}\z/, allow_blank: true }

  # Scopes
  scope :active, -> { kept }
  scope :by_position, -> { order(position: :asc) }
  scope :defaults, -> { where(is_default: true) }

  # Callbacks
  before_validation :set_default_color, if: -> { color.blank? }
  after_create :ensure_single_default, if: :is_default?

  # Instance methods

  def bookmarks_count
    bookmarks.kept.count
  end

  private

  def set_default_color
    self.color = "#6366f1"
  end

  def ensure_single_default
    # If this collection is marked as default, unset other defaults for this user
    user.collections.where.not(id: id).update_all(is_default: false)
  end
end
