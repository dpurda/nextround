class TemplateQuestion < ApplicationRecord
  belongs_to :interview_template

  validates :prompt, presence: true
end
