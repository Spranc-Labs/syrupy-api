# frozen_string_literal: true

class Goal < ApplicationRecord
  audited

  belongs_to :user

  validates :title, presence: true
  validates :status, inclusion: { in: %w[active completed paused archived] }
  validates :priority, inclusion: { in: %w[low medium high] }

  scope :filter_by_text, ->(text) {
    where("title ILIKE ? OR description ILIKE ?", "%#{text}%", "%#{text}%") if text.present?
  }

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :due_soon, -> { where(target_date: Date.current..1.week.from_now) }

  def completed?
    status == "completed"
  end

  def overdue?
    target_date.present? && target_date < Date.current && !completed?
  end

  def days_remaining
    return nil unless target_date.present?
    (target_date - Date.current).to_i
  end
end 