class JournalEntryBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :title,
    :content,
    :mood_rating,
    :created_at,
    :updated_at,
    :discarded_at,
    :formatted_date,
    :word_count,
    :ai_mood_score,
    :ai_mood_label,
    :ai_category,
    :ai_emotions,
    :ai_processing_time_ms,
    :ai_analyzed_at,
    :ai_analyzed?,
    :ai_mood_emoji,
    :ai_category_display,
    :dominant_emotion,
    :dominant_emotion_emoji
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
end 