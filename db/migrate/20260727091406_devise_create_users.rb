# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Rememberable
      t.datetime :remember_created_at

      ## NextRound: identity, role, invite-by-code
      t.string :name, null: false, default: ""
      t.integer :role, null: false, default: 0
      t.string :invitation_code
      t.datetime :invitation_code_generated_at
      t.datetime :claimed_at
      t.references :invited_by, foreign_key: { to_table: :users }, null: true

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :invitation_code, unique: true
  end
end
