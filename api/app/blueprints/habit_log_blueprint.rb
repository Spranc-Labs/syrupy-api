class HabitLogBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :logged_date,
    :completed,
    :notes,
    :created_at,
    :updated_at,
    :discarded_at,
    :completed?,
  )

  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { self.include_association?(options, :user) },
  )

  association(
    :habit,
    blueprint: HabitBlueprint,
    if: ->(*, options) { self.include_association?(options, :habit) },
  )
end