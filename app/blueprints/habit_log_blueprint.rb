# frozen_string_literal: true

class HabitLogBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :logged_date,
    :completed,
    :notes,
    :created_at,
    :updated_at,
    :discarded_at,
    :completed?
  )

  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { include_association?(options, :user) }
  )

  association(
    :habit,
    blueprint: HabitBlueprint,
    if: ->(*, options) { include_association?(options, :habit) }
  )
end
