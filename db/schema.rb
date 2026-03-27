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

ActiveRecord::Schema[8.1].define(version: 2026_03_24_210352) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "communities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_communities_on_name", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.float "ai_sentiment_score"
    t.integer "community_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "parent_message_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "user_ip", null: false
    t.index ["community_id"], name: "index_messages_on_community_id"
    t.index ["parent_message_id"], name: "index_messages_on_parent_message_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.string "reaction_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["message_id", "user_id", "reaction_type"], name: "index_reactions_on_message_user_and_type", unique: true
    t.index ["message_id"], name: "index_reactions_on_message_id"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "messages", "communities"
  add_foreign_key "messages", "messages", column: "parent_message_id"
  add_foreign_key "messages", "users"
  add_foreign_key "reactions", "messages"
  add_foreign_key "reactions", "users"
end
