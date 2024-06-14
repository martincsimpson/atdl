class AddDeferredReasonToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :deferred_reason, :string
  end
end
