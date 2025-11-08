# frozen_string_literal: true

class GoalBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :title,
    :description,
    :status,
    :priority,
    :target_date,
    :created_at,
    :updated_at,
    :discarded_at,
    :completed?,
    :overdue?,
    :days_remaining
  )

  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { include_association?(options, :user) }
  )
end
