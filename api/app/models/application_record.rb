# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  # Use 'discarded_at' field to soft delete records
  include Discard::Model
  # Ignore discarded records by default
  default_scope -> { kept }

  primary_abstract_class

  # Convenience method for filtering records by user permissions
  def self.by_permission_scope(user)
    Pundit.policy_scope!(user, self)
  end

  # Default scope for filtering records by text; case-insensitive.
  # Can be overridden in subclasses.
  scope :filter_by_text, ->(text) {
    if text.blank?
      return all
    end

    return where("name ILIKE ?", "%#{text}%")
  }
end 