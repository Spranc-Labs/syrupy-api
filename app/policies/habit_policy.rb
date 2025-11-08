# frozen_string_literal: true

class HabitPolicy < ApplicationPolicy
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

  def log_completion?
    owner_or_admin?
  end

  def toggle_active?
    owner_or_admin?
  end

  def history?
    owner_or_admin?
  end

  def streaks?
    true
  end

  def stats?
    true
  end

  def dashboard?
    true
  end

  def bulk_log?
    true
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
