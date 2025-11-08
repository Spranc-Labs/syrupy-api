# frozen_string_literal: true

class BookmarkPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.user == user
  end

  def create?
    true
  end

  def from_heyho?
    true
  end

  def update?
    record.user == user
  end

  def destroy?
    record.user == user
  end

  def mark_as_read?
    record.user == user
  end

  def archive?
    record.user == user
  end

  def favorite?
    record.user == user
  end

  def bulk_update?
    true
  end

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end
