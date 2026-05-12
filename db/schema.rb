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

ActiveRecord::Schema[8.0].define(version: 2026_05_12_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "goals", force: :cascade do |t|
    t.string "value_statement", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_goals_on_user_id", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subgoals", force: :cascade do |t|
    t.bigint "goal_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reward_title"
    t.text "reward_description"
    t.datetime "reward_claimed_at"
    t.index ["goal_id", "position"], name: "index_subgoals_on_goal_id_and_position"
    t.index ["goal_id"], name: "index_subgoals_on_goal_id"
  end

  create_table "todo_items", force: :cascade do |t|
    t.bigint "subgoal_id", null: false
    t.string "title", null: false
    t.text "memo"
    t.datetime "completed_at"
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_todo_items_on_completed_at"
    t.index ["subgoal_id", "position"], name: "index_todo_items_on_subgoal_id_and_position"
    t.index ["subgoal_id"], name: "index_todo_items_on_subgoal_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "goals", "users"
  add_foreign_key "subgoals", "goals"
  add_foreign_key "todo_items", "subgoals"
end
