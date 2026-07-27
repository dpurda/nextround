class InterviewerProfile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :expertise, :company, :title, presence: true
  validates :years_of_experience, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :user_must_be_interviewer

  def self.ransackable_attributes(_auth_object = nil)
    %w[expertise company title years_of_experience]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  private

  def user_must_be_interviewer
    errors.add(:user, "must have the interviewer role") if user && !user.interviewer?
  end
end
