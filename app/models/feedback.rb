class Feedback < ApplicationRecord
  belongs_to :interview

  enum :recommendation, { strong_hire: 0, hire: 1, no_hire: 2, strong_no_hire: 3 }

  validates :strengths, :improvements, presence: true
  validates :recommendation, presence: true
  validates :overall_rating, presence: true, inclusion: { in: 1..5 }
  validates :interview_id, uniqueness: true

  after_create :complete_interview

  def self.ransackable_attributes(_auth_object = nil)
    %w[recommendation overall_rating strengths improvements notes created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[interview]
  end

  private

  def complete_interview
    interview.update(status: :completed) unless interview.cancelled?
  end
end
