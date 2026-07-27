class Education < ApplicationRecord
  include CvEntry

  belongs_to :candidate_profile

  validates :institution, :degree, presence: true
end
