# frozen_string_literal: true

class ResourceContentBlueprint < Blueprinter::Base
  identifier :id

  fields :content, :created_at, :updated_at
end 