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

ActiveRecord::Schema[8.1].define(version: 2026_07_26_001000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analyses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind"
    t.text "result"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "analysis_exports", force: :cascade do |t|
    t.integer "analysis_id", null: false
    t.datetime "created_at", null: false
    t.string "format", null: false
    t.string "resolution_generation_status"
    t.datetime "updated_at", null: false
    t.index ["analysis_id"], name: "index_analysis_exports_on_analysis_id", unique: true
  end

  create_table "risk_assessment_resolutions", force: :cascade do |t|
    t.integer "analysis_export_id", null: false
    t.datetime "created_at", null: false
    t.text "explanation", null: false
    t.integer "finding_index", null: false
    t.string "impact_category", null: false
    t.text "resolution", null: false
    t.string "risk_type", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_export_id", "finding_index"], name: "index_resolutions_on_export_and_finding", unique: true
    t.index ["analysis_export_id"], name: "index_risk_assessment_resolutions_on_analysis_export_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analysis_exports", "analyses"
  add_foreign_key "risk_assessment_resolutions", "analysis_exports"
end
