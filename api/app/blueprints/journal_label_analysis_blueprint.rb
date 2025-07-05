class JournalLabelAnalysisBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :analysis_model,
    :model_version,
    :payload,
    :run_ms,
    :analyzed_at,
    :created_at,
    :updated_at
  )
end 