# frozen_string_literal: true

class CandidateProfilePolicy < ApplicationPolicy
  def show?
    update?
  end

  def new?
    create?
  end

  def create?
    user.admin? || (user.candidate? && record.user_id == user.id)
  end

  def edit?
    update?
  end

  def update?
    create?
  end
end
