class AddInterviewTemplateToInterviews < ActiveRecord::Migration[8.0]
  def change
    add_reference :interviews, :interview_template, foreign_key: true
  end
end
