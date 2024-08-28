class AddHiddenToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :hidden, :boolean
  end
end
