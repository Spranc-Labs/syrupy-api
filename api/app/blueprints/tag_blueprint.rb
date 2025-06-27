class TagBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :name,
    :color,
    :created_at,
    :updated_at,
    :discarded_at,
  )
end 