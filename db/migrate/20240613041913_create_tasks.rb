class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :name
      t.references :project, null: true, foreign_key: true
      t.references :parent_task, foreign_key: { to_table: :tasks }
      t.timestamps
    end
  end
end
