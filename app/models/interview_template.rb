class InterviewTemplate < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :template_questions, -> { order(:id) }, dependent: :destroy, inverse_of: :interview_template
  has_many :interviews, dependent: :nullify

  accepts_nested_attributes_for :template_questions, allow_destroy: true, reject_if: :all_blank

  enum :interview_type, { technical: 0, behavioral: 1, system_design: 2 }, default: :technical

  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name description interview_type created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[created_by template_questions]
  end
end
