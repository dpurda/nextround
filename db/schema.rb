# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_27_150137) do
  create_table "candidate_profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "phone"
    t.string "current_role"
    t.integer "years_of_experience"
    t.string "target_role"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.index ["user_id"], name: "index_candidate_profiles_on_user_id"
  end

  create_table "educations", force: :cascade do |t|
    t.integer "candidate_profile_id", null: false
    t.string "institution", null: false
    t.string "degree", null: false
    t.string "field_of_study"
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_educations_on_candidate_profile_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.integer "interview_id", null: false
    t.text "strengths", null: false
    t.text "improvements", null: false
    t.integer "recommendation", null: false
    t.integer "overall_rating", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_id"], name: "index_feedbacks_on_interview_id", unique: true
  end

  create_table "interviewer_profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "expertise"
    t.integer "years_of_experience"
    t.string "company"
    t.string "title"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_interviewer_profiles_on_user_id"
  end

  create_table "interviews", force: :cascade do |t|
    t.integer "interviewer_id", null: false
    t.integer "candidate_id", null: false
    t.string "title", null: false
    t.integer "interview_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "scheduled_at"
    t.integer "duration_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_interviews_on_candidate_id"
    t.index ["interviewer_id"], name: "index_interviews_on_interviewer_id"
    t.index ["scheduled_at"], name: "index_interviews_on_scheduled_at"
    t.index ["status"], name: "index_interviews_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.string "name", default: "", null: false
    t.integer "role", default: 0, null: false
    t.string "invitation_code"
    t.datetime "invitation_code_generated_at"
    t.datetime "claimed_at"
    t.integer "invited_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_code"], name: "index_users_on_invitation_code", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
  end

  create_table "work_experiences", force: :cascade do |t|
    t.integer "candidate_profile_id", null: false
    t.string "company", null: false
    t.string "title", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_work_experiences_on_candidate_profile_id"
  end

  add_foreign_key "candidate_profiles", "users"
  add_foreign_key "educations", "candidate_profiles"
  add_foreign_key "feedbacks", "interviews"
  add_foreign_key "interviewer_profiles", "users"
  add_foreign_key "interviews", "users", column: "candidate_id"
  add_foreign_key "interviews", "users", column: "interviewer_id"
  add_foreign_key "users", "users", column: "invited_by_id"
  add_foreign_key "work_experiences", "candidate_profiles"
end
