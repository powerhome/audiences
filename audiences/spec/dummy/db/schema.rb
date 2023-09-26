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

ActiveRecord::Schema[7.0].define(version: 2023_09_25_192149) do
  create_table "audiences_contexts", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.boolean "match_all", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_audiences_contexts_on_owner_type_and_owner_id", unique: true
  end

  create_table "audiences_contexts_resources", id: false, force: :cascade do |t|
    t.integer "context_id", null: false
    t.integer "resource_id", null: false
    t.index ["context_id", "resource_id"], name: "index_audiences_contexts_resources_on_context_id_and_resource_id"
  end

  create_table "audiences_resources", force: :cascade do |t|
    t.integer "resource_id"
    t.string "display"
    t.string "image_url"
    t.string "resource_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "example_owners", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
