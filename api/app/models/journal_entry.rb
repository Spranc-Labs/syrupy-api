class JournalEntry < ApplicationRecord
  audited

  belongs_to :user
  has_many :journal_entry_tags, dependent: :destroy
  has_many :tags, through: :journal_entry_tags

  validates :title, presence: true
  validates :content, presence: true
  validates :mood_rating, inclusion: { in: 1..10 }

  scope :filter_by_text, ->(text) {
    if text.present?
      where("title ILIKE ? OR content ILIKE ?", "%#{text}%", "%#{text}%")
    end
  }

  scope :by_mood_range, ->(min, max) {
    where(mood_rating: min..max) if min.present? && max.present?
  }

  scope :by_date_range, ->(start_date, end_date) {
    where(created_at: start_date..end_date) if start_date.present? && end_date.present?
  }

  scope :recent, -> { order(created_at: :desc) }

  def formatted_date
    created_at.strftime("%B %d, %Y")
  end

  def word_count
    content.split.size
  end
end 