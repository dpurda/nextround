class CreateCandidateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :candidate_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :phone
      t.string :current_role
      t.integer :years_of_experience
      t.string :target_role
      t.text :bio

      t.timestamps
    end
  end
end
