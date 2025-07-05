class JournalLabelAnalysis < ApplicationRecord
  belongs_to :journal_entry

  validates :analysis_model, presence: true
  validates :model_version, presence: true
  validates :analyzed_at, presence: true
  validates :payload, presence: true

  scope :by_model, ->(name, version = nil) {
    scope = where(analysis_model: name)
    scope = scope.where(model_version: version) if version.present?
    scope
  }

  scope :recent, -> { order(analyzed_at: :desc) }

  def categories
    payload.is_a?(Hash) ? payload : {}
  end

  def primary_category
    categories.dig('category')
  end

  def category_scores
    return {} unless payload.is_a?(Hash)
    
    payload.select { |k, v| k != 'category' && v.is_a?(Numeric) }
  end

  def confidence_score
    scores = category_scores.values.map(&:to_f)
    return 0 unless scores.any?
    
    scores.max - scores.min
  end
end 