# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_11_27_200326) do

  create_table "audiences_contexts", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.boolean "match_all", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "extra_users"
    t.index ["owner_type", "owner_id"], name: "index_audiences_contexts_on_owner_type_and_owner_id", unique: true
  end

  create_table "audiences_criterions", force: :cascade do |t|
    t.json "groups"
    t.integer "context_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "users"
    t.datetime "refreshed_at"
    t.index ["context_id"], name: "index_audiences_criterions_on_context_id"
  end

  create_table "example_memberships", force: :cascade do |t|
    t.integer "owner_id"
    t.integer "user_id"
    t.string "name"
    t.string "photo"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["owner_id"], name: "index_example_memberships_on_owner_id"
  end

  create_table "example_owners", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
