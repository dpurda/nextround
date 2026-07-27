module CvEntry
  extend ActiveSupport::Concern

  included do
    validates :start_date, presence: true
    validate :end_date_after_start_date

    scope :ordered, -> { order(start_date: :desc) }
  end

  def current?
    end_date.nil?
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, "must be after the start date") if end_date < start_date
  end
end
