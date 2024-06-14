class AddLogToRecurringTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :recurring_tasks, :log, :json
  end
end
