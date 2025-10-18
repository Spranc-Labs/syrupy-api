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
  field :label do |analysis|
    analysis.primary_category
  end

  # Unpacked category scores
  field :category_scores do |analysis|
    analysis.category_scores
  end

  # Confidence score derived from category scores
  field :confidence do |analysis|
    analysis.confidence_score
  end
end 