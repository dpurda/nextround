class CandidateProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :phone, :current_role, :target_role, :education, :location, presence: true
  validates :years_of_experience, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :user_must_be_candidate

  def self.ransackable_attributes(_auth_object = nil)
    %w[phone current_role target_role years_of_experience education location work_experience]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  private

  def user_must_be_candidate
    errors.add(:user, "must have the candidate role") if user && !user.candidate?
  end
end
