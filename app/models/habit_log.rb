# frozen_string_literal: true

class HabitLog < ApplicationRecord
  audited

  belongs_to :user
  belongs_to :habit

  validates :logged_date, presence: true, uniqueness: { scope: :habit_id }

  scope :completed, -> { where(completed: true) }
  scope :by_date_range, ->(start_date, end_date) {
    where(logged_date: start_date..end_date) if start_date.present? && end_date.present?
  }

  def completed?
    completed
  end
end 