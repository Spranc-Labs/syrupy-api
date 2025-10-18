# frozen_string_literal: true

class EmotionLabelAnalysis < ApplicationRecord
  belongs_to :journal_entry

  validates :analysis_model, presence: true
  validates :model_version, presence: true
  validates :analyzed_at, presence: true
  validates :payload, presence: true

  # Automatically derive top_emotion from payload after save
  after_save :update_top_emotion, if: :saved_change_to_payload?

  scope :by_model, ->(name, version = nil) {
    scope = where(analysis_model: name)
    scope = scope.where(model_version: version) if version.present?
    scope
  }

  scope :recent, -> { order(analyzed_at: :desc) }

  def emotion_scores
    payload.is_a?(Hash) ? payload : {}
  end

  def confidence_score
    return 0 unless emotion_scores.any?
    
    scores = emotion_scores.values.map(&:to_f)
    scores.max - scores.min
  end

  private

  def update_top_emotion
    return unless payload.is_a?(Hash) && payload.any?

    top_emotion_key = payload.max_by { |_, score| score.to_f }&.first
    update_column(:top_emotion, top_emotion_key) if top_emotion_key
  end
end 