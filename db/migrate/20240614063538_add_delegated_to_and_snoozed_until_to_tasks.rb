class AddDelegatedToAndSnoozedUntilToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :delegated_to, :string
    add_column :tasks, :snoozed_until, :datetime
  end
end
