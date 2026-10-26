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

ActiveRecord::Schema[8.1].define(version: 2026_10_26_143121) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "catalog_settings", force: :cascade do |t|
    t.string "vendor_name", default: "LGD USA", null: false
    t.string "title_template", default: "{remarks}", null: false
    t.text "photo_url_pattern"
    t.integer "photos_per_product", default: 8, null: false
    t.string "inventory_location_label"
    t.decimal "default_markup", precision: 8, scale: 2, default: "0.0", null: false
    t.jsonb "category_markups", default: {}, null: false
    t.text "sample_shopify_skus"
    t.boolean "auto_sync_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "supplier_products", force: :cascade do |t|
    t.string "stock_no", null: false
    t.string "title"
    t.text "remarks"
    t.string "category"
    t.string "metal"
    t.decimal "supplier_price", precision: 12, scale: 2
    t.integer "inhand_pcs", default: 0, null: false
    t.text "photo_url"
    t.boolean "demo", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_no"], name: "index_supplier_products_on_stock_no", unique: true
  end

  create_table "supplier_sync_states", force: :cascade do |t|
    t.datetime "last_attempt_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sync_events", force: :cascade do |t|
    t.string "event_type", null: false
    t.string "status", null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
