class MoodLogBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :rating,
    :notes,
    :logged_at,
    :created_at,
    :updated_at,
    :discarded_at,
    :mood_description,
  )

  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { self.include_association?(options, :user) },
  )
end 