class CreateInterviews < ActiveRecord::Migration[8.0]
  def change
    create_table :interviews do |t|
      t.references :interviewer, null: false, foreign_key: { to_table: :users }
      t.references :candidate, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.integer :interview_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at
      t.integer :duration_minutes

      t.timestamps
    end

    add_index :interviews, :status
    add_index :interviews, :scheduled_at
  end
end
