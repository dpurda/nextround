class CreateEducations < ActiveRecord::Migration[8.0]
  def change
    create_table :educations do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :institution, null: false
      t.string :degree, null: false
      t.string :field_of_study
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps
    end
  end
end
