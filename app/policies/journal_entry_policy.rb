# frozen_string_literal: true

class JournalEntryPolicy < ApplicationPolicy
  def index?
    true
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

  def analyze?
    owner_or_admin?
  end

  def emotion_stats?
    true
  end

  def category_stats?
    true
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
