# frozen_string_literal: true

class InterviewQuestionPolicy < ApplicationPolicy
  def update?
    user.admin? || (user.interviewer? && record.interview.interviewer_id == user.id)
  end

  def edit?
    update?
  end
end
