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