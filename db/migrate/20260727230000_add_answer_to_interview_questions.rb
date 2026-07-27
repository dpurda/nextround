class AddAnswerToInterviewQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :interview_questions, :answer, :text
  end
end
