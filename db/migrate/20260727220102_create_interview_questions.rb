class CreateInterviewQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_questions do |t|
      t.references :interview, null: false, foreign_key: true
      t.text :prompt, null: false
      t.text :notes
      t.boolean :covered, null: false, default: false

      t.timestamps
    end
  end
end
