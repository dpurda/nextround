# frozen_string_literal: true

class FeedbackPolicy < ApplicationPolicy
  def create?
    user.admin? || (user.interviewer? && record.interview.interviewer_id == user.id)
  end

  def update?
    create?
  end
end
