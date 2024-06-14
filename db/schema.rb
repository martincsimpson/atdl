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

ActiveRecord::Schema[7.1].define(version: 2024_06_14_090931) do
  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.integer "workspace_id"
    t.integer "parent_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_project_id"], name: "index_projects_on_parent_project_id"
    t.index ["workspace_id"], name: "index_projects_on_workspace_id"
  end

  create_table "recurring_tasks", force: :cascade do |t|
    t.string "name"
    t.string "schedule"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "log"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.integer "project_id"
    t.integer "parent_task_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "workflow_state"
    t.string "delegated_to"
    t.datetime "snoozed_until"
    t.string "deferred_reason"
    t.index ["parent_task_id"], name: "index_tasks_on_parent_task_id"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "projects", "projects", column: "parent_project_id"
  add_foreign_key "projects", "workspaces"
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "tasks", column: "parent_task_id"
end
