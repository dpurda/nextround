class CandidateProfile < ApplicationRecord
  belongs_to :user

  has_many :work_experiences, -> { ordered }, dependent: :destroy, inverse_of: :candidate_profile
  has_many :educations, -> { ordered }, dependent: :destroy, inverse_of: :candidate_profile

  accepts_nested_attributes_for :work_experiences, :educations, allow_destroy: true, reject_if: :all_blank

  validates :user_id, uniqueness: true
  validates :phone, :current_role, :target_role, :location, presence: true
  validates :years_of_experience, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :user_must_be_candidate

  def self.ransackable_attributes(_auth_object = nil)
    %w[phone current_role target_role years_of_experience location]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user work_experiences educations]
  end

  private

  def user_must_be_candidate
    errors.add(:user, "must have the candidate role") if user && !user.candidate?
  end
end
