# frozen_string_literal: true

class TagBlueprint < ApplicationBlueprint
  identifier :id

  fields(
    :name,
    :color,
    :kind,
    :created_at,
    :updated_at,
    :discarded_at,
  )
end 