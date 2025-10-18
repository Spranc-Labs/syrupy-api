# frozen_string_literal: true

class EmotionLog < ApplicationRecord
  belongs_to :user

  enum emotion_label: {
    happy: 0,
    sad: 1,
    angry: 2,
    fearful: 3,
    surprised: 4,
    disgusted: 5,
    neutral: 6,
    excited: 7,
    anxious: 8,
    grateful: 9,
    frustrated: 10,
    content: 11,
    overwhelmed: 12,
    peaceful: 13,
    lonely: 14
  }

  validates :emotion_label, presence: true
  validates :captured_at, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :by_emotion, ->(emotion) { where(emotion_label: emotion) if emotion.present? }
  scope :by_date_range, ->(start_date, end_date) {
    where(captured_at: start_date..end_date) if start_date.present? && end_date.present?
  }
  scope :recent, -> { order(captured_at: :desc) }
  scope :today, -> { where(captured_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(captured_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(captured_at: 1.month.ago..Time.current) }

  def mood_emoji
    case emotion_label.to_s
    when 'happy' then '😊'
    when 'sad' then '😢'
    when 'angry' then '😠'
    when 'fearful' then '😨'
    when 'surprised' then '😲'
    when 'disgusted' then '🤢'
    when 'neutral' then '😐'
    when 'excited' then '🤩'
    when 'anxious' then '😰'
    when 'grateful' then '🙏'
    when 'frustrated' then '😤'
    when 'content' then '😌'
    when 'overwhelmed' then '😵'
    when 'peaceful' then '😇'
    when 'lonely' then '😔'
    else emoji.presence || '❓'
    end
  end

  def formatted_captured_at
    captured_at.strftime("%B %d, %Y at %I:%M %p")
  end
end 