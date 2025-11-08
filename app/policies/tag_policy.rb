# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    admin? # Only admins can create tags for now
  end

  def update?
    admin? # Only admins can update tags for now
  end

  def destroy?
    admin? # Only admins can delete tags for now
  end

  class Scope < Scope
    def resolve
      # Tags are global - all authenticated users can see them
      scope.all
    end
  end
end
