class Tag < ApplicationRecord
  audited

  has_many :journal_entry_tags, dependent: :destroy
  has_many :journal_entries, through: :journal_entry_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :color, format: { with: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, message: "must be a valid hex color" }

  scope :filter_by_text, ->(text) {
    where("name ILIKE ?", "%#{text}%") if text.present?
  }

  scope :popular, -> { joins(:journal_entries).group("tags.id").order("COUNT(journal_entries.id) DESC") }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end 