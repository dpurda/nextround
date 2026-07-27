class CreateTemplateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :template_questions do |t|
      t.references :interview_template, null: false, foreign_key: true
      t.text :prompt, null: false

      t.timestamps
    end
  end
end
