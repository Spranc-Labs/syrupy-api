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

  def analyze_ai?
    owner_or_admin?
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end 