# frozen_string_literal: true

class InterviewPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || record.interviewer_id == user.id || record.candidate_id == user.id
  end

  def create?
    user.admin? || user.interviewer?
  end

  def update?
    user.admin? || (user.interviewer? && record.interviewer_id == user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.interviewer?
        scope.where(interviewer_id: user.id)
      elsif user.candidate?
        scope.where(candidate_id: user.id)
      else
        scope.none
      end
    end
  end
end
