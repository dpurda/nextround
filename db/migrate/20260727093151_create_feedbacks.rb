class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.references :interview, null: false, foreign_key: true, index: { unique: true }
      t.text :strengths, null: false
      t.text :improvements, null: false
      t.integer :recommendation, null: false
      t.integer :overall_rating, null: false
      t.text :notes

      t.timestamps
    end
  end
end
