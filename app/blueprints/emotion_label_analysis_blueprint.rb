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

  field :emotion_scores, &:emotion_scores

  field :confidence, &:confidence_score
end
