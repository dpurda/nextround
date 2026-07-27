class WorkExperience < ApplicationRecord
  include CvEntry

  belongs_to :candidate_profile

  validates :company, :title, presence: true
end
