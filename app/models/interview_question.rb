class InterviewQuestion < ApplicationRecord
  belongs_to :interview

  validates :prompt, presence: true

  after_update :start_interview_on_first_answer

  private

  def start_interview_on_first_answer
    return unless saved_change_to_answer? && answer.present?

    interview.update(status: :in_progress) if interview.scheduled?
  end
end
