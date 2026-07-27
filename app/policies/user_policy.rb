# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.interviewer?
  end

  def new?
    invitable_roles.any?
  end

  def create?
    invitable_roles.include?(record.role.to_sym)
  end

  def show?
    user.admin? || record.invited_by_id == user.id
  end

  # Roles this user is allowed to invite: admin can invite interviewers or
  # candidates; interviewers can only invite candidates; candidates can't
  # invite anyone.
  def invitable_roles
    return %i[interviewer candidate] if user.admin?
    return %i[candidate] if user.interviewer?

    []
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.where.not(invited_by_id: nil)
      elsif user.interviewer?
        scope.where(invited_by_id: user.id)
      else
        scope.none
      end
    end
  end
end
