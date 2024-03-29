# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110927123526) do

  create_table "comments", :force => true do |t|
    t.text     "content"
    t.integer  "video_id",   :null => false
    t.integer  "user_id",    :null => false
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                             :null => false
    t.string   "password"
    t.string   "nick"
    t.string   "fb_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password", :limit => 128
    t.string   "salt",               :limit => 128
    t.string   "confirmation_token", :limit => 128
    t.string   "remember_token",     :limit => 128
    t.integer  "status",                            :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

  create_table "video_taggees", :force => true do |t|
    t.string   "contact_id", :null => false
    t.string   "video_id",   :null => false
    t.datetime "created_at"
  end

  create_table "videos", :force => true do |t|
    t.integer  "user_id",                            :null => false
    t.string   "title"
    t.integer  "views_count",         :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "duration",                           :null => false
    t.integer  "category",                           :null => false
    t.string   "description"
    t.string   "keywords"
    t.string   "source_content_type"
    t.string   "source_file_name"
    t.integer  "source_file_size"
    t.string   "state"
  end

  add_index "videos", ["category"], :name => "by_category"
  add_index "videos", ["user_id"], :name => "by_user_id"

end
