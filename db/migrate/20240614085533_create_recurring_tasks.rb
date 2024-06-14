class CreateRecurringTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :recurring_tasks do |t|
      t.string :name
      t.string :schedule

      t.timestamps
    end
  end
end
