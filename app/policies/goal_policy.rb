# frozen_string_literal: true

class GoalPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner_or_admin?
  end

  def create?
    user.present?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end

  def mark_completed?
    owner_or_admin?
  end

  def mark_in_progress?
    owner_or_admin?
  end

  def stats?
    true
  end

  def dashboard?
    true
  end

  def bulk_update?
    true
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
