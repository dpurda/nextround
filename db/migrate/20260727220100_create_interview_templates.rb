class CreateInterviewTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_templates do |t|
      t.string :name, null: false
      t.text :description
      t.integer :interview_type, null: false, default: 0
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
