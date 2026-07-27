# frozen_string_literal: true

class InterviewTemplatePolicy < ApplicationPolicy
  def index?
    user.admin? || user.interviewer?
  end

  def show?
    index?
  end

  def create?
    index?
  end

  def update?
    user.admin? || (user.interviewer? && record.created_by_id == user.id)
  end

  def destroy?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.interviewer?
        scope.all
      else
        scope.none
      end
    end
  end
end
