class DropOrphanedSkillTables < ActiveRecord::Migration[8.0]
  def change
    # Leftover from schema drift outside this app's migration history — no
    # Skill model, controller, or view ever existed for these, unused.
    drop_table :skill_taggings do |t|
      t.integer :skill_id, null: false
      t.string :taggable_type, null: false
      t.integer :taggable_id, null: false
      t.timestamps
    end

    drop_table :skills do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
