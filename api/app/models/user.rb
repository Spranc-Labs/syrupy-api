class User < ApplicationRecord
  audited

  belongs_to :account
  has_many :journal_entries, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :mood_logs, dependent: :destroy
  has_many :habits, dependent: :destroy
  has_many :habit_logs, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  scope :filter_by_text, ->(query) {
    if query.present?
      where(
        "users.first_name ilike :query or " \
        "users.last_name ilike :query or " \
        "users.email ilike :query or " \
        "concat_ws(' ', users.first_name, users.last_name) ilike :query",
        query: "%#{query}%",
      )
    end
  }

  def full_name
    [first_name, last_name].select(&:present?).join(" ")
  end

  def username
    account&.email || email
  end
end