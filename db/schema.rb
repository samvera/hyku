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

ActiveRecord::Schema.define(version: 2024_12_05_212513) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "account_cross_searches", force: :cascade do |t|
    t.bigint "search_account_id"
    t.bigint "full_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["full_account_id"], name: "index_account_cross_searches_on_full_account_id"
    t.index ["search_account_id"], name: "index_account_cross_searches_on_search_account_id"
  end

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.string "tenant"
    t.string "cname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "solr_endpoint_id"
    t.integer "fcrepo_endpoint_id"
    t.string "name"
    t.integer "redis_endpoint_id"
    t.boolean "is_public", default: false
    t.jsonb "settings", default: {}
    t.bigint "data_cite_endpoint_id"
    t.boolean "search_only", default: false
    t.index ["cname", "tenant"], name: "index_accounts_on_cname_and_tenant"
    t.index ["cname"], name: "index_accounts_on_cname", unique: true
    t.index ["data_cite_endpoint_id"], name: "index_accounts_on_data_cite_endpoint_id"
    t.index ["fcrepo_endpoint_id"], name: "index_accounts_on_fcrepo_endpoint_id", unique: true
    t.index ["redis_endpoint_id"], name: "index_accounts_on_redis_endpoint_id", unique: true
    t.index ["settings"], name: "index_accounts_on_settings", using: :gin
    t.index ["solr_endpoint_id"], name: "index_accounts_on_solr_endpoint_id", unique: true
  end

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "bulkrax_entries", force: :cascade do |t|
    t.string "identifier"
    t.string "collection_ids"
    t.string "type"
    t.bigint "importerexporter_id"
    t.text "raw_metadata"
    t.text "parsed_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_error_at"
    t.datetime "last_succeeded_at"
    t.string "importerexporter_type", default: "Bulkrax::Importer"
    t.integer "import_attempts", default: 0
    t.string "status_message", default: "Pending"
    t.string "error_class"
    t.index ["identifier", "importerexporter_id", "importerexporter_type"], name: "bulkrax_identifier_idx"
    t.index ["importerexporter_id", "importerexporter_type", "id"], name: "index_bulkrax_entries_on_importerexporter_id_type_and_id"
    t.index ["importerexporter_id", "importerexporter_type"], name: "bulkrax_entries_importerexporter_idx"
    t.index ["type"], name: "index_bulkrax_entries_on_type"
  end

  create_table "bulkrax_exporter_runs", force: :cascade do |t|
    t.bigint "exporter_id"
    t.integer "total_work_entries", default: 0
    t.integer "enqueued_records", default: 0
    t.integer "processed_records", default: 0
    t.integer "deleted_records", default: 0
    t.integer "failed_records", default: 0
    t.index ["exporter_id"], name: "index_bulkrax_exporter_runs_on_exporter_id"
  end

  create_table "bulkrax_exporters", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.string "parser_klass"
    t.integer "limit"
    t.text "parser_fields"
    t.text "field_mapping"
    t.string "export_source"
    t.string "export_from"
    t.string "export_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_error_at"
    t.datetime "last_succeeded_at"
    t.date "start_date"
    t.date "finish_date"
    t.string "work_visibility"
    t.string "workflow_status"
    t.boolean "include_thumbnails", default: false
    t.boolean "generated_metadata", default: false
    t.string "status_message", default: "Pending"
    t.string "error_class"
    t.index ["user_id"], name: "index_bulkrax_exporters_on_user_id"
  end

  create_table "bulkrax_importer_runs", force: :cascade do |t|
    t.bigint "importer_id"
    t.integer "total_work_entries", default: 0
    t.integer "enqueued_records", default: 0
    t.integer "processed_records", default: 0
    t.integer "deleted_records", default: 0
    t.integer "failed_records", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "processed_collections", default: 0
    t.integer "failed_collections", default: 0
    t.integer "total_collection_entries", default: 0
    t.integer "processed_relationships", default: 0
    t.integer "failed_relationships", default: 0
    t.text "invalid_records"
    t.integer "processed_file_sets", default: 0
    t.integer "failed_file_sets", default: 0
    t.integer "total_file_set_entries", default: 0
    t.integer "processed_works", default: 0
    t.integer "failed_works", default: 0
    t.index ["importer_id"], name: "index_bulkrax_importer_runs_on_importer_id"
  end

  create_table "bulkrax_importers", force: :cascade do |t|
    t.string "name"
    t.string "admin_set_id"
    t.bigint "user_id"
    t.string "frequency"
    t.string "parser_klass"
    t.integer "limit"
    t.text "parser_fields"
    t.text "field_mapping"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "validate_only"
    t.datetime "last_error_at"
    t.datetime "last_succeeded_at"
    t.string "status_message", default: "Pending"
    t.datetime "last_imported_at"
    t.datetime "next_import_at"
    t.string "error_class"
    t.index ["user_id"], name: "index_bulkrax_importers_on_user_id"
  end

  create_table "bulkrax_pending_relationships", force: :cascade do |t|
    t.bigint "importer_run_id", null: false
    t.string "parent_id", null: false
    t.string "child_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", default: 0
    t.string "status_message", default: "Pending"
    t.index ["child_id"], name: "index_bulkrax_pending_relationships_on_child_id"
    t.index ["importer_run_id"], name: "index_bulkrax_pending_relationships_on_importer_run_id"
    t.index ["parent_id"], name: "index_bulkrax_pending_relationships_on_parent_id"
  end

  create_table "bulkrax_statuses", force: :cascade do |t|
    t.string "status_message"
    t.string "error_class"
    t.text "error_message"
    t.text "error_backtrace"
    t.integer "statusable_id"
    t.string "statusable_type"
    t.integer "runnable_id"
    t.string "runnable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["error_class"], name: "index_bulkrax_statuses_on_error_class"
    t.index ["runnable_id", "runnable_type"], name: "bulkrax_statuses_runnable_idx"
    t.index ["statusable_id", "statusable_type"], name: "bulkrax_statuses_statusable_idx"
  end

  create_table "checksum_audit_logs", id: :serial, force: :cascade do |t|
    t.string "file_set_id"
    t.string "file_id"
    t.string "checked_uri"
    t.string "expected_result"
    t.string "actual_result"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "passed"
    t.index ["checked_uri"], name: "index_checksum_audit_logs_on_checked_uri"
    t.index ["file_set_id", "file_id"], name: "by_file_set_id_and_file_id"
  end

  create_table "collection_branding_infos", force: :cascade do |t|
    t.string "collection_id"
    t.string "role"
    t.string "local_path"
    t.string "alt_text"
    t.string "target_url"
    t.integer "height"
    t.integer "width"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collection_type_participants", force: :cascade do |t|
    t.bigint "hyrax_collection_type_id"
    t.string "agent_type"
    t.string "agent_id"
    t.string "access"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hyrax_collection_type_id"], name: "hyrax_collection_type_id"
  end

  create_table "content_blocks", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_key"
    t.integer "site_id"
    t.index ["site_id"], name: "index_content_blocks_on_site_id"
  end

  create_table "curation_concerns_operations", id: :serial, force: :cascade do |t|
    t.string "status"
    t.string "operation_type"
    t.string "job_class"
    t.string "job_id"
    t.string "type"
    t.text "message"
    t.integer "user_id"
    t.integer "parent_id"
    t.integer "lft", null: false
    t.integer "rgt", null: false
    t.integer "depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lft"], name: "index_curation_concerns_operations_on_lft"
    t.index ["parent_id"], name: "index_curation_concerns_operations_on_parent_id"
    t.index ["rgt"], name: "index_curation_concerns_operations_on_rgt"
    t.index ["user_id"], name: "index_curation_concerns_operations_on_user_id"
  end

  create_table "domain_names", force: :cascade do |t|
    t.bigint "account_id"
    t.string "cname"
    t.boolean "is_active", default: true
    t.boolean "is_ssl_enabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_domain_names_on_account_id"
  end

  create_table "domain_terms", id: :serial, force: :cascade do |t|
    t.string "model"
    t.string "term"
    t.index ["model", "term"], name: "terms_by_model_and_term"
  end

  create_table "domain_terms_local_authorities", id: false, force: :cascade do |t|
    t.integer "domain_term_id"
    t.integer "local_authority_id"
    t.index ["domain_term_id", "local_authority_id"], name: "dtla_by_ids2"
    t.index ["local_authority_id", "domain_term_id"], name: "dtla_by_ids1"
  end

  create_table "endpoints", id: :serial, force: :cascade do |t|
    t.string "type"
    t.binary "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "featured_collections", force: :cascade do |t|
    t.integer "order", default: 6
    t.string "collection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_featured_collections_on_collection_id"
    t.index ["order"], name: "index_featured_collections_on_order"
  end

  create_table "featured_works", id: :serial, force: :cascade do |t|
    t.integer "order", default: 6
    t.string "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order"], name: "index_featured_works_on_order"
    t.index ["work_id"], name: "index_featured_works_on_work_id"
  end

  create_table "file_download_stats", id: :serial, force: :cascade do |t|
    t.datetime "date"
    t.integer "downloads"
    t.string "file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["file_id"], name: "index_file_download_stats_on_file_id"
    t.index ["user_id"], name: "index_file_download_stats_on_user_id"
  end

  create_table "file_view_stats", id: :serial, force: :cascade do |t|
    t.datetime "date"
    t.integer "views"
    t.string "file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["file_id"], name: "index_file_view_stats_on_file_id"
    t.index ["user_id"], name: "index_file_view_stats_on_user_id"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
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
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "group_roles", force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_roles_on_group_id"
    t.index ["role_id"], name: "index_group_roles_on_role_id"
  end

  create_table "hyrax_collection_types", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "machine_id"
    t.boolean "nestable", default: true, null: false
    t.boolean "discoverable", default: true, null: false
    t.boolean "sharable", default: true, null: false
    t.boolean "allow_multiple_membership", default: true, null: false
    t.boolean "require_membership", default: false, null: false
    t.boolean "assigns_workflow", default: false, null: false
    t.boolean "assigns_visibility", default: false, null: false
    t.boolean "share_applies_to_new_works", default: true, null: false
    t.boolean "brandable", default: true, null: false
    t.string "badge_color", default: "#663333"
    t.index ["machine_id"], name: "index_hyrax_collection_types_on_machine_id", unique: true
  end

  create_table "hyrax_counter_metrics", force: :cascade do |t|
    t.string "worktype"
    t.string "resource_type"
    t.string "work_id"
    t.date "date"
    t.integer "total_item_investigations"
    t.integer "total_item_requests"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "title"
    t.integer "year_of_publication"
    t.string "publisher"
    t.string "author"
    t.index ["date"], name: "index_hyrax_counter_metrics_on_date"
    t.index ["resource_type"], name: "index_hyrax_counter_metrics_on_resource_type"
    t.index ["work_id"], name: "index_hyrax_counter_metrics_on_work_id"
    t.index ["worktype"], name: "index_hyrax_counter_metrics_on_worktype"
  end

  create_table "hyrax_default_administrative_set", force: :cascade do |t|
    t.string "default_admin_set_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hyrax_features", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hyrax_flexible_schemas", force: :cascade do |t|
    t.text "profile"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "contexts"
  end

  create_table "hyrax_groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "humanized_name"
  end

  create_table "identity_providers", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.jsonb "options"
    t.string "logo_image"
    t.string "logo_image_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "iiif_print_derivative_attachments", id: :serial, force: :cascade do |t|
    t.string "fileset_id"
    t.string "path"
    t.string "destination_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fileset_id"], name: "index_iiif_print_derivative_attachments_on_fileset_id"
  end

  create_table "iiif_print_ingest_file_relations", id: :serial, force: :cascade do |t|
    t.string "file_path"
    t.string "derivative_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_path"], name: "index_iiif_print_ingest_file_relations_on_file_path"
  end

  create_table "iiif_print_pending_relationships", force: :cascade do |t|
    t.string "child_title", null: false
    t.string "parent_id", null: false
    t.string "child_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "parent_model"
    t.string "child_model"
    t.string "file_id"
    t.index ["parent_id"], name: "index_iiif_print_pending_relationships_on_parent_id"
  end

  create_table "job_io_wrappers", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "uploaded_file_id"
    t.string "file_set_id"
    t.string "mime_type"
    t.string "original_name"
    t.string "path"
    t.string "relation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uploaded_file_id"], name: "index_job_io_wrappers_on_uploaded_file_id"
    t.index ["user_id"], name: "index_job_io_wrappers_on_user_id"
  end

  create_table "local_authorities", id: :serial, force: :cascade do |t|
    t.string "name"
  end

  create_table "local_authority_entries", id: :serial, force: :cascade do |t|
    t.integer "local_authority_id"
    t.string "label"
    t.string "uri"
    t.index ["local_authority_id", "label"], name: "entries_by_term_and_label"
    t.index ["local_authority_id", "uri"], name: "entries_by_term_and_uri"
  end

  create_table "mailboxer_conversation_opt_outs", id: :serial, force: :cascade do |t|
    t.string "unsubscriber_type"
    t.integer "unsubscriber_id"
    t.integer "conversation_id"
    t.index ["conversation_id"], name: "index_mailboxer_conversation_opt_outs_on_conversation_id"
    t.index ["unsubscriber_id", "unsubscriber_type"], name: "index_mailboxer_conversation_opt_outs_on_unsubscriber_id_type"
  end

  create_table "mailboxer_conversations", id: :serial, force: :cascade do |t|
    t.string "subject", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mailboxer_notifications", id: :serial, force: :cascade do |t|
    t.string "type"
    t.text "body"
    t.string "subject", default: ""
    t.string "sender_type"
    t.integer "sender_id"
    t.integer "conversation_id"
    t.boolean "draft", default: false
    t.string "notification_code"
    t.string "notified_object_type"
    t.integer "notified_object_id"
    t.string "attachment"
    t.datetime "updated_at", null: false
    t.datetime "created_at", null: false
    t.boolean "global", default: false
    t.datetime "expires"
    t.index ["conversation_id"], name: "index_mailboxer_notifications_on_conversation_id"
    t.index ["notified_object_id", "notified_object_type"], name: "index_mailboxer_notifications_on_notified_object_id_and_type"
    t.index ["sender_id", "sender_type"], name: "index_mailboxer_notifications_on_sender_id_and_sender_type"
    t.index ["type"], name: "index_mailboxer_notifications_on_type"
  end

  create_table "mailboxer_receipts", id: :serial, force: :cascade do |t|
    t.string "receiver_type"
    t.integer "receiver_id"
    t.integer "notification_id", null: false
    t.boolean "is_read", default: false
    t.boolean "trashed", default: false
    t.boolean "deleted", default: false
    t.string "mailbox_type", limit: 25
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_delivered", default: false
    t.string "delivery_method"
    t.string "message_id"
    t.index ["notification_id"], name: "index_mailboxer_receipts_on_notification_id"
    t.index ["receiver_id", "receiver_type"], name: "index_mailboxer_receipts_on_receiver_id_and_receiver_type"
  end

  create_table "minter_states", id: :serial, force: :cascade do |t|
    t.string "namespace", default: "default", null: false
    t.string "template", null: false
    t.text "counters"
    t.bigint "seq", default: 0
    t.binary "rand"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace"], name: "index_minter_states_on_namespace", unique: true
  end

  create_table "orm_resources", id: :text, default: -> { "(uuid_generate_v4())::text" }, force: :cascade do |t|
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "internal_resource"
    t.integer "lock_version"
    t.index "(((metadata -> 'bulkrax_identifier'::text) ->> 0))", name: "index_on_bulkrax_identifier", where: "((metadata -> 'bulkrax_identifier'::text) IS NOT NULL)"
    t.index ["internal_resource"], name: "index_orm_resources_on_internal_resource"
    t.index ["metadata"], name: "index_orm_resources_on_metadata", using: :gin
    t.index ["metadata"], name: "index_orm_resources_on_metadata_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
    t.index ["updated_at"], name: "index_orm_resources_on_updated_at"
  end

  create_table "permission_template_accesses", id: :serial, force: :cascade do |t|
    t.integer "permission_template_id"
    t.string "agent_type"
    t.string "agent_id"
    t.string "access"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["permission_template_id", "agent_id", "agent_type", "access"], name: "uk_permission_template_accesses", unique: true
  end

  create_table "permission_templates", id: :serial, force: :cascade do |t|
    t.string "source_id"
    t.string "visibility"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "release_date"
    t.string "release_period"
    t.index ["source_id"], name: "index_permission_templates_on_source_id", unique: true
  end

  create_table "proxy_deposit_requests", id: :serial, force: :cascade do |t|
    t.string "work_id", null: false
    t.integer "sending_user_id", null: false
    t.integer "receiving_user_id", null: false
    t.datetime "fulfillment_date"
    t.string "status", default: "pending", null: false
    t.text "sender_comment"
    t.text "receiver_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiving_user_id"], name: "index_proxy_deposit_requests_on_receiving_user_id"
    t.index ["sending_user_id"], name: "index_proxy_deposit_requests_on_sending_user_id"
  end

  create_table "proxy_deposit_rights", id: :serial, force: :cascade do |t|
    t.integer "grantor_id"
    t.integer "grantee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grantee_id"], name: "index_proxy_deposit_rights_on_grantee_id"
    t.index ["grantor_id"], name: "index_proxy_deposit_rights_on_grantor_id"
  end

  create_table "qa_local_authorities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_qa_local_authorities_on_name", unique: true
  end

  create_table "qa_local_authority_entries", id: :serial, force: :cascade do |t|
    t.integer "local_authority_id"
    t.string "label"
    t.string "uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id"], name: "index_qa_local_authority_entries_on_local_authority_id"
    t.index ["uri"], name: "index_qa_local_authority_entries_on_uri", unique: true
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "sort_value"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "single_use_links", id: :serial, force: :cascade do |t|
    t.string "download_key"
    t.string "path"
    t.string "item_id"
    t.datetime "expires"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sipity_agents", id: :serial, force: :cascade do |t|
    t.string "proxy_for_id", null: false
    t.string "proxy_for_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proxy_for_id", "proxy_for_type"], name: "sipity_agents_proxy_for", unique: true
  end

  create_table "sipity_comments", id: :serial, force: :cascade do |t|
    t.integer "entity_id", null: false
    t.integer "agent_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_sipity_comments_on_agent_id"
    t.index ["created_at"], name: "index_sipity_comments_on_created_at"
    t.index ["entity_id"], name: "index_sipity_comments_on_entity_id"
  end

  create_table "sipity_entities", id: :serial, force: :cascade do |t|
    t.string "proxy_for_global_id", null: false
    t.integer "workflow_id", null: false
    t.integer "workflow_state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proxy_for_global_id"], name: "sipity_entities_proxy_for_global_id", unique: true
    t.index ["workflow_id"], name: "index_sipity_entities_on_workflow_id"
    t.index ["workflow_state_id"], name: "index_sipity_entities_on_workflow_state_id"
  end

  create_table "sipity_entity_specific_responsibilities", id: :serial, force: :cascade do |t|
    t.integer "workflow_role_id", null: false
    t.integer "entity_id", null: false
    t.integer "agent_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "sipity_entity_specific_responsibilities_agent"
    t.index ["entity_id"], name: "sipity_entity_specific_responsibilities_entity"
    t.index ["workflow_role_id", "entity_id", "agent_id"], name: "sipity_entity_specific_responsibilities_aggregate", unique: true
    t.index ["workflow_role_id"], name: "sipity_entity_specific_responsibilities_role"
  end

  create_table "sipity_notifiable_contexts", id: :serial, force: :cascade do |t|
    t.integer "scope_for_notification_id", null: false
    t.string "scope_for_notification_type", null: false
    t.string "reason_for_notification", null: false
    t.integer "notification_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id"], name: "sipity_notifiable_contexts_notification_id"
    t.index ["scope_for_notification_id", "scope_for_notification_type", "reason_for_notification", "notification_id"], name: "sipity_notifiable_contexts_concern_surrogate", unique: true
    t.index ["scope_for_notification_id", "scope_for_notification_type", "reason_for_notification"], name: "sipity_notifiable_contexts_concern_context"
    t.index ["scope_for_notification_id", "scope_for_notification_type"], name: "sipity_notifiable_contexts_concern"
  end

  create_table "sipity_notification_recipients", id: :serial, force: :cascade do |t|
    t.integer "notification_id", null: false
    t.integer "role_id", null: false
    t.string "recipient_strategy", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id", "role_id", "recipient_strategy"], name: "sipity_notifications_recipients_surrogate"
    t.index ["notification_id"], name: "sipity_notification_recipients_notification"
    t.index ["recipient_strategy"], name: "sipity_notification_recipients_recipient_strategy"
    t.index ["role_id"], name: "sipity_notification_recipients_role"
  end

  create_table "sipity_notifications", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "notification_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sipity_notifications_on_name", unique: true
    t.index ["notification_type"], name: "index_sipity_notifications_on_notification_type"
  end

  create_table "sipity_roles", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sipity_roles_on_name", unique: true
  end

  create_table "sipity_workflow_actions", id: :serial, force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.integer "resulting_workflow_state_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resulting_workflow_state_id"], name: "sipity_workflow_actions_resulting_workflow_state"
    t.index ["workflow_id", "name"], name: "sipity_workflow_actions_aggregate", unique: true
    t.index ["workflow_id"], name: "sipity_workflow_actions_workflow"
  end

  create_table "sipity_workflow_methods", id: :serial, force: :cascade do |t|
    t.string "service_name", null: false
    t.integer "weight", null: false
    t.integer "workflow_action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_action_id"], name: "index_sipity_workflow_methods_on_workflow_action_id"
  end

  create_table "sipity_workflow_responsibilities", id: :serial, force: :cascade do |t|
    t.integer "agent_id", null: false
    t.integer "workflow_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "workflow_role_id"], name: "sipity_workflow_responsibilities_aggregate", unique: true
  end

  create_table "sipity_workflow_roles", id: :serial, force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.integer "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_id", "role_id"], name: "sipity_workflow_roles_aggregate", unique: true
  end

  create_table "sipity_workflow_state_action_permissions", id: :serial, force: :cascade do |t|
    t.integer "workflow_role_id", null: false
    t.integer "workflow_state_action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_role_id", "workflow_state_action_id"], name: "sipity_workflow_state_action_permissions_aggregate", unique: true
  end

  create_table "sipity_workflow_state_actions", id: :serial, force: :cascade do |t|
    t.integer "originating_workflow_state_id", null: false
    t.integer "workflow_action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["originating_workflow_state_id", "workflow_action_id"], name: "sipity_workflow_state_actions_aggregate", unique: true
  end

  create_table "sipity_workflow_states", id: :serial, force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sipity_workflow_states_on_name"
    t.index ["workflow_id", "name"], name: "sipity_type_state_aggregate", unique: true
  end

  create_table "sipity_workflows", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "label"
    t.integer "permission_template_id"
    t.boolean "active"
    t.boolean "allows_access_grant"
    t.index ["permission_template_id", "name"], name: "index_sipity_workflows_on_permission_template_and_name", unique: true
  end

  create_table "sites", id: :serial, force: :cascade do |t|
    t.string "application_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "institution_name"
    t.string "institution_name_full"
    t.string "banner_image"
    t.string "logo_image"
    t.string "default_collection_image"
    t.string "default_work_image"
    t.text "available_works", default: [], array: true
    t.string "directory_image"
    t.string "contact_email"
    t.string "home_theme"
    t.string "show_theme"
    t.string "search_theme"
    t.string "favicon"
    t.string "directory_image_alt_text"
  end

  create_table "subject_local_authority_entries", id: :serial, force: :cascade do |t|
    t.string "label"
    t.string "lowerLabel"
    t.string "url"
    t.index ["lowerLabel"], name: "entries_by_lower_label"
  end

  create_table "tinymce_assets", id: :serial, force: :cascade do |t|
    t.string "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trophies", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "uploaded_files", id: :serial, force: :cascade do |t|
    t.string "file"
    t.integer "user_id"
    t.string "file_set_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "filename"
    t.index ["file_set_uri"], name: "index_uploaded_files_on_file_set_uri"
    t.index ["user_id"], name: "index_uploaded_files_on_user_id"
  end

  create_table "user_batch_emails", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "last_emailed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_user_batch_emails_on_user_id"
  end

  create_table "user_stats", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "date"
    t.integer "file_views"
    t.integer "file_downloads"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "work_views"
    t.index ["user_id"], name: "index_user_stats_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "guest", default: false
    t.string "facebook_handle"
    t.string "twitter_handle"
    t.string "googleplus_handle"
    t.string "display_name"
    t.string "address"
    t.string "admin_area"
    t.string "department"
    t.string "title"
    t.string "office"
    t.string "chat_id"
    t.string "website"
    t.string "affiliation"
    t.string "telephone"
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.text "group_list"
    t.datetime "groups_last_update"
    t.string "linkedin_handle"
    t.string "orcid"
    t.string "arkivo_token"
    t.string "arkivo_subscription"
    t.binary "zotero_token"
    t.string "zotero_userid"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.string "preferred_locale"
    t.string "provider"
    t.string "uid"
    t.string "batch_email_frequency", default: "never"
    t.string "api_key"
    t.index ["api_key"], name: "index_users_on_api_key"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
  end

  create_table "version_committers", id: :serial, force: :cascade do |t|
    t.string "obj_id"
    t.string "datastream_id"
    t.string "version_id"
    t.string "committer_login"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_view_stats", id: :serial, force: :cascade do |t|
    t.datetime "date"
    t.integer "work_views"
    t.string "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_work_view_stats_on_user_id"
    t.index ["work_id"], name: "index_work_view_stats_on_work_id"
  end

  add_foreign_key "account_cross_searches", "accounts", column: "full_account_id"
  add_foreign_key "account_cross_searches", "accounts", column: "search_account_id"
  add_foreign_key "accounts", "endpoints", column: "fcrepo_endpoint_id", on_delete: :nullify
  add_foreign_key "accounts", "endpoints", column: "redis_endpoint_id", on_delete: :nullify
  add_foreign_key "accounts", "endpoints", column: "solr_endpoint_id", on_delete: :nullify
  add_foreign_key "bulkrax_exporter_runs", "bulkrax_exporters", column: "exporter_id"
  add_foreign_key "bulkrax_importer_runs", "bulkrax_importers", column: "importer_id"
  add_foreign_key "bulkrax_pending_relationships", "bulkrax_importer_runs", column: "importer_run_id"
  add_foreign_key "collection_type_participants", "hyrax_collection_types"
  add_foreign_key "content_blocks", "sites"
  add_foreign_key "mailboxer_conversation_opt_outs", "mailboxer_conversations", column: "conversation_id", name: "mb_opt_outs_on_conversations_id"
  add_foreign_key "mailboxer_notifications", "mailboxer_conversations", column: "conversation_id", name: "notifications_on_conversation_id"
  add_foreign_key "mailboxer_receipts", "mailboxer_notifications", column: "notification_id", name: "receipts_on_notification_id"
  add_foreign_key "permission_template_accesses", "permission_templates"
  add_foreign_key "qa_local_authority_entries", "qa_local_authorities", column: "local_authority_id"
end
