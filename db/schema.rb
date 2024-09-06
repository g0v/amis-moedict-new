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

ActiveRecord::Schema[7.2].define(version: 2024_09_06_050047) do
  create_table "descriptions", force: :cascade do |t|
    t.integer "term_id"
    t.string "content", limit: 500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description_type", limit: 3
    t.index ["term_id"], name: "index_descriptions_on_term_id"
  end

  create_table "dictionaries", force: :cascade do |t|
    t.string "name", limit: 50
    t.string "dialect", limit: 15
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "examples", force: :cascade do |t|
    t.integer "description_id"
    t.string "content"
    t.string "content_zh"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["description_id"], name: "index_examples_on_description_id"
  end

  create_table "stems", force: :cascade do |t|
    t.string "name", limit: 40
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_stems_on_name", unique: true
  end

  create_table "synonyms", force: :cascade do |t|
    t.integer "description_id"
    t.string "term_type", limit: 5
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["description_id"], name: "index_synonyms_on_description_id"
  end

  create_table "terms", force: :cascade do |t|
    t.integer "dictionary_id"
    t.integer "stem_id"
    t.string "name"
    t.string "lower_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customized_text", limit: 500
    t.index ["dictionary_id"], name: "index_terms_on_dictionary_id"
    t.index ["lower_name"], name: "index_terms_on_lower_name"
    t.index ["name"], name: "index_terms_on_name"
    t.index ["stem_id"], name: "index_terms_on_stem_id"
  end
end
