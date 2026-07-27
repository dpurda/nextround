class Interview < ApplicationRecord
  belongs_to :interviewer, class_name: "User"
  belongs_to :candidate, class_name: "User"
  has_one :feedback, dependent: :destroy

  enum :interview_type, { technical: 0, behavioral: 1, system_design: 2 }, default: :technical
  enum :status, { scheduled: 0, in_progress: 1, completed: 2, cancelled: 3 }, default: :scheduled

  validates :title, presence: true
  validate :interviewer_must_be_interviewer
  validate :candidate_must_be_candidate
  validate :feedback_required_to_complete

  scope :for_interviewer, ->(user) { where(interviewer: user) }
  scope :for_candidate, ->(user) { where(candidate: user) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[title interview_type status scheduled_at duration_minutes created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[interviewer candidate feedback]
  end

  private

  def interviewer_must_be_interviewer
    errors.add(:interviewer, "must have the interviewer role") if interviewer && !interviewer.interviewer?
  end

  def candidate_must_be_candidate
    errors.add(:candidate, "must have the candidate role") if candidate && !candidate.candidate?
  end

  def feedback_required_to_complete
    errors.add(:status, "cannot be completed without feedback") if status_changed? && completed? && feedback.blank?
  end
end
