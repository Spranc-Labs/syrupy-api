# frozen_string_literal: true

class JournalEntryBlueprint < ApplicationBlueprint
  identifier :id

  # Core fields
  fields(
    :title,
    :content,
    :created_at,
    :updated_at,
    :discarded_at,
    :formatted_date
  )

  # Timestamp of when analysis was performed (nil if not analyzed)
  field :analyzed_at do |journal_entry|
    journal_entry.emotion_label_analysis&.analyzed_at ||
      journal_entry.journal_label_analysis&.analyzed_at
  end

  # For lightweight responses (when not including full analysis associations)
  # Only included when user doesn't request full emotion_label_analysis
  field :primary_emotion,
        if: ->(*, options) { !include_association?(options, :emotion_label_analysis) }

  # Only included when user doesn't request full journal_label_analysis
  field :current_category,
        if: ->(*, options) { !include_association?(options, :journal_label_analysis) }

  # Full nested analysis objects (when requested)
  association(
    :emotion_label_analysis,
    blueprint: EmotionLabelAnalysisBlueprint,
    if: ->(*, options) { include_association?(options, :emotion_label_analysis) }
  )

  association(
    :journal_label_analysis,
    blueprint: JournalLabelAnalysisBlueprint,
    if: ->(*, options) { include_association?(options, :journal_label_analysis) }
  )

  association(
    :tags,
    blueprint: TagBlueprint,
    if: ->(*, options) { include_association?(options, :tags) }
  )

  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { include_association?(options, :user) }
  )
end
