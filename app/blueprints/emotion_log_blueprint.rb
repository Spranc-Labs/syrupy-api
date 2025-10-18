# frozen_string_literal: true

class EmotionLogBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :emotion_label,
    :emoji,
    :note,
    :captured_at,
    :created_at,
    :updated_at
  )

  field :mood_emoji do |emotion_log|
    case emotion_log.emotion_label
    when 'happy' then '😊'
    when 'sad' then '😢'
    when 'angry' then '😠'
    when 'fearful' then '😨'
    when 'surprised' then '😲'
    when 'disgusted' then '🤢'
    when 'neutral' then '😐'
    when 'excited' then '🤩'
    when 'anxious' then '😰'
    when 'grateful' then '🙏'
    when 'frustrated' then '😤'
    when 'content' then '😌'
    when 'overwhelmed' then '😵'
    when 'peaceful' then '☮️'
    when 'lonely' then '😔'
    else '😐'
    end
  end

  # Format: "July 06, 2025 at 2:30 PM"
  field :formatted_captured_at do |emotion_log|
    emotion_log.captured_at.strftime("%B %d, %Y at %l:%M %p")
  end

  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { self.include_association?(options, :user) },
  )
end 