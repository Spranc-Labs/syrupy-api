# frozen_string_literal: true

class JournalLabelAnalysisBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :analysis_model,
    :model_version,
    :analyzed_at,
    :created_at,
    :updated_at
  )

  # Primary category label
  field :label, &:primary_category

  # Unpacked category scores
  field :category_scores, &:category_scores

  # Confidence score derived from category scores
  field :confidence, &:confidence_score
end
