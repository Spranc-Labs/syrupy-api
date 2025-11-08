# frozen_string_literal: true

class MoodLog < ApplicationRecord
  audited

  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..10 }
  validates :logged_at, presence: true

  scope :recent, -> { order(logged_at: :desc) }
  scope :by_date_range, lambda { |start_date, end_date|
    where(logged_at: start_date..end_date) if start_date.present? && end_date.present?
  }

  def mood_description
    case rating
    when 1..2
      'Very Low'
    when 3..4
      'Low'
    when 5..6
      'Neutral'
    when 7..8
      'Good'
    when 9..10
      'Excellent'
    end
  end
end
