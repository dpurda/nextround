class InterviewQuestion < ApplicationRecord
  belongs_to :interview

  validates :prompt, presence: true
end
