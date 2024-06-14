class AddFlaggedToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :flagged, :boolean, default: false
  end
end
