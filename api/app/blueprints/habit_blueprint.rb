class HabitBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :name,
    :description,
    :frequency,
    :active,
    :created_at,
    :updated_at,
    :discarded_at,
    :current_streak,
  )

  field :completion_rate_30_days do |habit|
    habit.completion_rate(days: 30)
  end

  association(
    :user,
    blueprint: UserBlueprint,
    if: ->(*, options) { self.include_association?(options, :user) },
  )

  association(
    :habit_logs,
    blueprint: HabitLogBlueprint,
    if: ->(*, options) { self.include_association?(options, :habit_logs) },
  )
end 