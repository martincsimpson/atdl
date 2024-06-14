class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.references :workspace, null: true, foreign_key: true
      t.references :parent_project, foreign_key: { to_table: :projects }

      t.timestamps
    end
  end
end
