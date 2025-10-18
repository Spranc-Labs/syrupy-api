# frozen_string_literal: true

class Resource < ApplicationRecord
  belongs_to :user
  has_one :resource_content, dependent: :destroy
  has_many :resource_tags, dependent: :destroy
  has_many :tags, through: :resource_tags

  enum status: { pending: 0, processed: 1, failed: 2 }

  validates :url, presence: true, format: URI::regexp(%w[http https])
  validates :user, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  def domain
    URI.parse(url).host rescue nil
  end

  def rss_feed_url
    metadata.dig('rss_feed_url')
  end

  def has_content?
    resource_content.present?
  end
end 