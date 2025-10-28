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

ActiveRecord::Schema[7.1].define(version: 2025_10_28_215559) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "plpgsql"

  create_table "account_active_session_keys", force: :cascade do |t|
    t.bigint "account_id"
    t.string "session_id"
    t.datetime "created_at", null: false
    t.datetime "last_use", null: false
    t.index ["account_id", "session_id"], name: "index_account_active_session_keys_on_account_id_and_session_id"
    t.index ["account_id"], name: "index_account_active_session_keys_on_account_id"
    t.index ["session_id"], name: "index_account_active_session_keys_on_session_id"
  end

  create_table "account_lockouts", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_login_change_keys", force: :cascade do |t|
    t.string "key", null: false
    t.string "login", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_login_failures", force: :cascade do |t|
    t.integer "number", default: 1, null: false
  end

  create_table "account_password_hashes", force: :cascade do |t|
    t.string "password_hash", null: false
  end

  create_table "account_password_reset_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_remember_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_verification_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "accounts", force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.citext "email", null: false
    t.string "password_digest"
    t.index ["email"], name: "index_accounts_on_email", unique: true, where: "(status = ANY (ARRAY[1, 2]))"
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "emotion_label_analyses", force: :cascade do |t|
    t.bigint "journal_entry_id", null: false
    t.string "analysis_model", null: false
    t.string "model_version", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "top_emotion"
    t.integer "run_ms"
    t.datetime "analyzed_at", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analyzed_at"], name: "index_emotion_label_analyses_on_analyzed_at"
    t.index ["discarded_at"], name: "index_emotion_label_analyses_on_discarded_at"
    t.index ["journal_entry_id"], name: "index_emotion_label_analyses_on_journal_entry_id"
    t.index ["top_emotion"], name: "index_emotion_label_analyses_on_top_emotion"
  end

  create_table "emotion_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "emotion_label", null: false
    t.string "emoji"
    t.text "note"
    t.datetime "captured_at", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["captured_at"], name: "index_emotion_logs_on_captured_at"
    t.index ["discarded_at"], name: "index_emotion_logs_on_discarded_at"
    t.index ["emotion_label"], name: "index_emotion_logs_on_emotion_label"
    t.index ["user_id", "captured_at"], name: "index_emotion_logs_on_user_id_and_captured_at"
    t.index ["user_id"], name: "index_emotion_logs_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "active", null: false
    t.string "priority", default: "medium", null: false
    t.date "target_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_goals_on_discarded_at"
    t.index ["priority"], name: "index_goals_on_priority"
    t.index ["status"], name: "index_goals_on_status"
    t.index ["target_date"], name: "index_goals_on_target_date"
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "habit_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "habit_id", null: false
    t.date "logged_date", null: false
    t.boolean "completed", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["completed"], name: "index_habit_logs_on_completed"
    t.index ["discarded_at"], name: "index_habit_logs_on_discarded_at"
    t.index ["habit_id", "logged_date"], name: "index_habit_logs_on_habit_id_and_logged_date", unique: true
    t.index ["habit_id"], name: "index_habit_logs_on_habit_id"
    t.index ["logged_date"], name: "index_habit_logs_on_logged_date"
    t.index ["user_id"], name: "index_habit_logs_on_user_id"
  end

  create_table "habits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "frequency", default: "daily", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["active"], name: "index_habits_on_active"
    t.index ["discarded_at"], name: "index_habits_on_discarded_at"
    t.index ["frequency"], name: "index_habits_on_frequency"
    t.index ["user_id"], name: "index_habits_on_user_id"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.bigint "emotion_label_analysis_id"
    t.bigint "journal_label_analysis_id"
    t.index ["discarded_at"], name: "index_journal_entries_on_discarded_at"
    t.index ["emotion_label_analysis_id"], name: "index_journal_entries_on_emotion_label_analysis_id"
    t.index ["journal_label_analysis_id"], name: "index_journal_entries_on_journal_label_analysis_id"
    t.index ["user_id", "created_at"], name: "index_journal_entries_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_journal_entries_on_user_id"
  end

  create_table "journal_entry_tags", force: :cascade do |t|
    t.bigint "journal_entry_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["journal_entry_id", "tag_id"], name: "index_journal_entry_tags_on_journal_entry_id_and_tag_id", unique: true
    t.index ["journal_entry_id"], name: "index_journal_entry_tags_on_journal_entry_id"
    t.index ["tag_id"], name: "index_journal_entry_tags_on_tag_id"
  end

  create_table "journal_label_analyses", force: :cascade do |t|
    t.bigint "journal_entry_id", null: false
    t.string "analysis_model", null: false
    t.string "model_version", null: false
    t.jsonb "payload", default: {}, null: false
    t.integer "run_ms"
    t.datetime "analyzed_at", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analyzed_at"], name: "index_journal_label_analyses_on_analyzed_at"
    t.index ["discarded_at"], name: "index_journal_label_analyses_on_discarded_at"
    t.index ["journal_entry_id"], name: "index_journal_label_analyses_on_journal_entry_id"
  end

  create_table "mood_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "rating", null: false
    t.text "notes"
    t.datetime "logged_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_mood_logs_on_discarded_at"
    t.index ["logged_at"], name: "index_mood_logs_on_logged_at"
    t.index ["rating"], name: "index_mood_logs_on_rating"
    t.index ["user_id", "logged_at"], name: "index_mood_logs_on_user_id_and_logged_at"
    t.index ["user_id"], name: "index_mood_logs_on_user_id"
  end

  create_table "resource_contents", force: :cascade do |t|
    t.bigint "resource_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_resource_contents_on_discarded_at"
    t.index ["resource_id"], name: "index_resource_contents_on_resource_id", unique: true
  end

  create_table "resource_tags", force: :cascade do |t|
    t.bigint "resource_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_resource_tags_on_discarded_at"
    t.index ["resource_id", "tag_id"], name: "index_resource_tags_on_resource_id_and_tag_id", unique: true
    t.index ["resource_id"], name: "index_resource_tags_on_resource_id"
    t.index ["tag_id"], name: "index_resource_tags_on_tag_id"
  end

  create_table "resources", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "url", null: false
    t.string "title"
    t.integer "status", default: 0
    t.datetime "scraped_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_resources_on_discarded_at"
    t.index ["metadata"], name: "index_resources_on_metadata", using: :gin
    t.index ["status"], name: "index_resources_on_status"
    t.index ["url"], name: "index_resources_on_url"
    t.index ["user_id"], name: "index_resources_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#6366f1"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.string "kind", default: "user", null: false
    t.index ["discarded_at"], name: "index_tags_on_discarded_at"
    t.index ["kind"], name: "index_tags_on_kind"
    t.index ["name", "kind"], name: "index_tags_on_name_and_kind", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.integer "heyho_user_id"
    t.datetime "heyho_linked_at"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["heyho_user_id"], name: "index_users_on_heyho_user_id", unique: true
  end

  add_foreign_key "account_active_session_keys", "accounts"
  add_foreign_key "account_lockouts", "accounts", column: "id"
  add_foreign_key "account_login_change_keys", "accounts", column: "id"
  add_foreign_key "account_login_failures", "accounts", column: "id"
  add_foreign_key "account_password_hashes", "accounts", column: "id"
  add_foreign_key "account_password_reset_keys", "accounts", column: "id"
  add_foreign_key "account_remember_keys", "accounts", column: "id"
  add_foreign_key "account_verification_keys", "accounts", column: "id"
  add_foreign_key "emotion_label_analyses", "journal_entries"
  add_foreign_key "emotion_logs", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "habit_logs", "habits"
  add_foreign_key "habit_logs", "users"
  add_foreign_key "habits", "users"
  add_foreign_key "journal_entries", "emotion_label_analyses", on_delete: :nullify
  add_foreign_key "journal_entries", "journal_label_analyses", on_delete: :nullify
  add_foreign_key "journal_entries", "users"
  add_foreign_key "journal_entry_tags", "journal_entries"
  add_foreign_key "journal_entry_tags", "tags"
  add_foreign_key "journal_label_analyses", "journal_entries"
  add_foreign_key "mood_logs", "users"
  add_foreign_key "resource_contents", "resources"
  add_foreign_key "resource_tags", "resources"
  add_foreign_key "resource_tags", "tags"
  add_foreign_key "resources", "users"
  add_foreign_key "users", "accounts"
end
