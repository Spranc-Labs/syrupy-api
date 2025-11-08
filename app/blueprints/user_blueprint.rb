# frozen_string_literal: true

class UserBlueprint < ApplicationBlueprint
  fields :id, :first_name, :last_name, :email, :created_at, :updated_at

  field :full_name do |user|
    "#{user.first_name} #{user.last_name}".strip
  end

  field :username do |user|
    user.email
  end
end
