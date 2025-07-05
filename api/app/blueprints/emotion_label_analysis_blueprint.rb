class EmotionLabelAnalysisBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :analysis_model,
    :model_version,
    :payload,
    :top_emotion,
    :run_ms,
    :analyzed_at,
    :created_at,
    :updated_at
  )
end 