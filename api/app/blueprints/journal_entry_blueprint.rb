class JournalEntryBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :title,
    :content,
    :created_at,
    :updated_at,
    :discarded_at,
    :formatted_date,
    :word_count,
    :analyzed?,
    :current_category,
    :category_display,
    :primary_emotion,
    :primary_emotion_emoji
  )



  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { self.include_association?(options, :user) },
  )

  association(
    :tags,
    blueprint: TagBlueprint,
    if: ->(*, options) { self.include_association?(options, :tags) },
  )

  association(
    :emotion_label_analysis,
    blueprint: EmotionLabelAnalysisBlueprint,
    if: ->(*, options) { self.include_association?(options, :emotion_label_analysis) },
  )

  association(
    :journal_label_analysis,
    blueprint: JournalLabelAnalysisBlueprint,
    if: ->(*, options) { self.include_association?(options, :journal_label_analysis) },
  )
end 