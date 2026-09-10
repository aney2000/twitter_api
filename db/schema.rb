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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_130000) do
  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "tweet_id", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["tweet_id"], name: "index_comments_on_tweet_id"
    t.index ["uuid"], name: "index_comments_on_uuid", unique: true
  end

  create_table "resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image_url"
    t.integer "resourceable_id", null: false
    t.string "resourceable_type", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["resourceable_type", "resourceable_id"], name: "index_resources_on_resourceable"
  end

  create_table "tweets", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["uuid"], name: "index_tweets_on_uuid", unique: true
  end

  add_foreign_key "comments", "tweets"
end
