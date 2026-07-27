class CreateWorkExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :work_experiences do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :company, null: false
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.text :description

      t.timestamps
    end
  end
end
