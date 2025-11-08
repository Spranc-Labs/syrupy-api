# frozen_string_literal: true

class Habit < ApplicationRecord
  audited

  belongs_to :user
  has_many :habit_logs, dependent: :destroy

  validates :name, presence: true
  validates :frequency, inclusion: { in: %w[daily weekly monthly] }

  scope :filter_by_text, lambda { |text|
    where('name ILIKE ? OR description ILIKE ?', "%#{text}%", "%#{text}%") if text.present?
  }

  scope :active, -> { where(active: true) }
  scope :by_frequency, ->(frequency) { where(frequency: frequency) if frequency.present? }

  def current_streak
    return 0 unless habit_logs.exists?

    streak = 0
    current_date = Date.current

    loop do
      log = habit_logs.find_by(logged_date: current_date)
      break unless log&.completed?

      streak += 1
      current_date -= frequency_days
    end

    streak
  end

  def completion_rate(days: 30)
    start_date = days.days.ago.to_date
    end_date = Date.current

    total_expected = expected_logs_count(start_date, end_date)
    return 0 if total_expected.zero?

    completed_count = habit_logs.where(
      logged_date: start_date..end_date,
      completed: true
    ).count

    (completed_count.to_f / total_expected * 100).round(1)
  end

  private

  def frequency_days
    case frequency
    when 'daily' then 1
    when 'weekly' then 7
    when 'monthly' then 30
    end
  end

  def expected_logs_count(start_date, end_date)
    case frequency
    when 'daily'
      (end_date - start_date).to_i + 1
    when 'weekly'
      ((end_date - start_date) / 7).to_i + 1
    when 'monthly'
      ((end_date - start_date) / 30).to_i + 1
    end
  end
end
