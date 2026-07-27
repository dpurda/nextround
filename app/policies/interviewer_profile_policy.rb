# frozen_string_literal: true

class InterviewerProfilePolicy < ApplicationPolicy
  def show?
    update?
  end

  def new?
    create?
  end

  def create?
    user.admin? || (user.interviewer? && record.user_id == user.id)
  end

  def edit?
    update?
  end

  def update?
    create?
  end
end
