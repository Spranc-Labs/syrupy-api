# frozen_string_literal: true

# Not using ApplicationRecord to avoid automatic inclusion of discard gem
class Account < ActiveRecord::Base
  self.table_name = 'accounts'

  has_secure_password

  module Status
    UNVERIFIED = 1
    VERIFIED = 2
    CLOSED = 3
  end

  enum status: {
    unverified: Status::UNVERIFIED,
    verified: Status::VERIFIED,
    closed: Status::CLOSED
  }

  has_one :user, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  def email
    super&.downcase
  end

  scope :filter_by_text, lambda { |query|
    where('email ilike :query', query: "%#{query}%") if query.present?
  }
end
