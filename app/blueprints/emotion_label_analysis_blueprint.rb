# frozen_string_literal: true

class EmotionLabelAnalysisBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :analysis_model,
    :model_version,
    :top_emotion,
    :analyzed_at,
    :created_at,
    :updated_at
  )

  field :emotion_scores do |analysis|
    analysis.emotion_scores
  end

  field :confidence do |analysis|
    analysis.confidence_score
  end
end
