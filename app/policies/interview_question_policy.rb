# frozen_string_literal: true

class InterviewQuestionPolicy < ApplicationPolicy
  def update?
    interviewer_owner? || answering_candidate?
  end

  def edit?
    update?
  end

  private

  def interviewer_owner?
    user.admin? || (user.interviewer? && record.interview.interviewer_id == user.id)
  end

  def answering_candidate?
    user.candidate? && record.interview.candidate_id == user.id
  end
end
