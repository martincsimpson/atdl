class AddHiddenToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :hidden, :boolean
  end
end
