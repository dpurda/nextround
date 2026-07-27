class CreateInterviewerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :interviewer_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.text :expertise
      t.integer :years_of_experience
      t.string :company
      t.string :title
      t.text :bio

      t.timestamps
    end
  end
end
